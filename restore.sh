#!/bin/bash

set -euo pipefail
source "$HOME/backup-project/config/backup.conf"

BACKUP_DATE="$1"
BACKUP_DIR="$BACKUP_ROOT/$BACKUP_DATE"
if [[ ! -d "$BACKUP_DIR" ]]; then
    echo "[ERROR] Backup not found: $BACKUP_DIR"
    exit 1

fi

echo "[WARNING] You are about to restore:"
echo "Backup: $BACKUP_DIR"
echo "Target: $SOURCE"

read -r -p "Are you sure you want to restore? [y/N]: " CONFIRM

if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
    echo "[INFO] Restore cancelled."
    exit 0
fi

rsync -a \
    "$BACKUP_DIR/" \
    "$SOURCE/"
echo "[SUCCESS] Restore completed successfully."

