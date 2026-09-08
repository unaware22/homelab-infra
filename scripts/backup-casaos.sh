#!/bin/bash
set -euo pipefail

# === KONFIGURASI VARIABEL ===
SOURCE_DIR="/etc/casaos"
BACKUP_DEST="/home/devops/backups/casaos"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILENAME="casaos_backup_${TIMESTAMP}.tar.gz"
LOG_FILE="/home/devops/backups/backup.log"
RETENTION_DAYS=7

# === FUNGSI LOGGING ===
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log_message "=== Memulai proses backup CasaOS ==="

# 1. Validasi direktori sumber
if [ ! -d "$SOURCE_DIR" ]; then
    log_message "ERROR: Direktori sumber $SOURCE_DIR tidak ditemukan!"
    exit 1
fi

# 2. Kompresi dan Arsip data
log_message "Mengompres $SOURCE_DIR ke $BACKUP_DEST/$BACKUP_FILENAME..."
tar -czf "${BACKUP_DEST}/${BACKUP_FILENAME}" -C "$(dirname "$SOURCE_DIR")" "$(basename "$SOURCE_DIR")"

# 3. Validasi hasil kompresi
if [ -f "${BACKUP_DEST}/${BACKUP_FILENAME}" ]; then
    FILE_SIZE=$(du -h "${BACKUP_DEST}/${BACKUP_FILENAME}" | cut -f1)
    log_message "SUCCESS: Backup selesai dibuat dengan ukuran $FILE_SIZE."
else
    log_message "ERROR: File backup gagal terbuat!"
    exit 1
fi

# 4. Retention Policy: Hapus backup yang lebih lama dari 7 hari
log_message "Membersihkan arsip backup yang berumur lebih dari $RETENTION_DAYS hari..."
DELETED_FILES=$(find "$BACKUP_DEST" -type f -name "casaos_backup_*.tar.gz" -mtime +"$RETENTION_DAYS" -print -delete)

if [ -n "$DELETED_FILES" ]; then
    log_message "File lama berikut telah dihapus:"
    echo "$DELETED_FILES" | tee -a "$LOG_FILE"
else
    log_message "Tidak ada file lama yang perlu dibersihkan."
fi

log_message "=== Backup selesai dengan aman ==="
