#!/bin/bash

set -euo pipefail

# ==========================================
# Linux Backup System
# Version: 1.0
# ==========================================

# ---------- Configuration ----------
source "$HOME/backup-project/config/backup.conf"

BACKUP_DATE=$(date +%Y-%m-%d_%H-%M-%S)
BACKUP_DIR="$BACKUP_ROOT/$BACKUP_DATE"
WEEKLY_DATE=$(date +%Y-%m-%d)

WEEKLY_DIR="$WEEKLY_ROOT/$WEEKLY_DATE"


LOG_FILE="$HOME/backup-project/logs/backup.log"


# ---------- Logging ----------

log() {
    echo "[$(date)] $1" >> "$LOG_FILE"
}


# ---------- Error Handling ----------

error_handler() {
    echo "[$(date)] [ERROR] Line: $LINENO | Command: $BASH_COMMAND" >> "$LOG_FILE"
}

trap 'error_handler' ERR


# ---------- Find Previous Backup ----------

PREVIOUS_BACKUP=$(find "$BACKUP_ROOT" \
    -mindepth 1 \
    -maxdepth 1 \
    -type d | sort | tail -n 1)


# ---------- Disk Space Check ----------

SOURCE_SIZE=$(du -sb "$SOURCE" | awk '{print $1}')

AVAILABLE_SPACE=$(df -B1 --output=avail "$BACKUP_ROOT" | tail -n 1)

echo "[INFO] Source size      : $SOURCE_SIZE bytes"
echo "[INFO] Available space : $AVAILABLE_SPACE bytes"

log "Source size: $SOURCE_SIZE bytes"
log "Available space: $AVAILABLE_SPACE bytes"


if (( AVAILABLE_SPACE < SOURCE_SIZE )); then

    echo "[ERROR] Not enough disk space."
    log "Not enough disk space."

    exit 1

fi


echo "[INFO] Disk space check passed."
log "Disk space check passed."


# ---------- Prepare Backup Directory ----------

mkdir -p "$BACKUP_DIR"


echo "=========================================="
echo "        Linux Backup System"
echo "=========================================="


echo "[INFO] Backup started"
echo "[INFO] Source      : $SOURCE"
echo "[INFO] Destination : $BACKUP_DIR"


log "Backup started"
log "Source: $SOURCE"
log "Destination: $BACKUP_DIR"


# ---------- Perform Backup ----------

if [[ -z "$PREVIOUS_BACKUP" ]]; then

    echo "[INFO] No previous backup found."
    echo "[INFO] Performing FULL backup..."

    log "No previous backup found."
    log "Performing FULL backup."

    rsync -a --info=progress2 \
        "$SOURCE/" \
        "$BACKUP_DIR/"

else

    echo "[INFO] Previous backup found:"
    echo "       $PREVIOUS_BACKUP"

    echo "[INFO] Performing snapshot backup..."

    log "Previous backup found: $PREVIOUS_BACKUP"
    log "Performing snapshot backup."

    rsync -a --info=progress2 \
        --link-dest="$PREVIOUS_BACKUP" \
        "$SOURCE/" \
        "$BACKUP_DIR/"

fi


# ---------- Retention Policy ----------

BACKUP_COUNT=$(find "$BACKUP_ROOT" \
    -mindepth 1 \
    -maxdepth 1 \
    -type d | wc -l)


echo "[INFO] Total backups: $BACKUP_COUNT"
echo "[INFO] Retention: $RETENTION_COUNT"


log "Total backups: $BACKUP_COUNT"
log "Retention: $RETENTION_COUNT"


if (( BACKUP_COUNT > RETENTION_COUNT )); then

    DELETE_COUNT=$((BACKUP_COUNT - RETENTION_COUNT))

    echo "[INFO] Backups to remove: $DELETE_COUNT"
    log "Backups to remove: $DELETE_COUNT"

    find "$BACKUP_ROOT" \
        -mindepth 1 \
        -maxdepth 1 \
        -type d | sort | head -n "$DELETE_COUNT" |
    while read -r OLD_BACKUP; do

        echo "[INFO] Removing old backup: $OLD_BACKUP"
        log "Removing old backup: $OLD_BACKUP"

        rm -rf "$OLD_BACKUP"

    done

else

    echo "[INFO] No old backups need to be removed."
    log "No old backups need to be removed."

fi
if [[ "$(date +%u)" -eq 7 ]]; then

    echo "[INFO] Sunday detected. Weekly backup is due."
    log "Sunday detected. Weekly backup is due."

    if [[ -d "$WEEKLY_DIR" ]]; then

        echo "[INFO] Weekly backup already exists for today."
        log "Weekly backup already exists for today."

    else

        echo "[INFO] No Weekly backup found for today."
        log "No Weekly backup found for today."

        mkdir -p "$WEEKLY_DIR"

        LATEST_DAILY=$(find "$BACKUP_ROOT" \
            -mindepth 1 \
            -maxdepth 1 \
            -type d | sort | tail -n 1)

        echo "[INFO] Latest Daily backup:"
        echo "       $LATEST_DAILY"

        log "Latest Daily backup: $LATEST_DAILY"

        rsync -a \
            "$LATEST_DAILY/" \
            "$WEEKLY_DIR/"

        echo "[INFO] Weekly backup created:"
        echo "       $WEEKLY_DIR"

        log "Weekly backup created: $WEEKLY_DIR"

    fi

fi

# ---------- Weekly Retention ----------

WEEKLY_COUNT=$(find "$WEEKLY_ROOT" \
    -mindepth 1 \
    -maxdepth 1 \
    -type d | wc -l)

echo "[INFO] Total Weekly backups: $WEEKLY_COUNT"
echo "[INFO] Weekly Retention: $WEEKLY_RETENTION_COUNT"

log "Total Weekly backups: $WEEKLY_COUNT"
log "Weekly Retention: $WEEKLY_RETENTION_COUNT"


if (( WEEKLY_COUNT > WEEKLY_RETENTION_COUNT )); then

    WEEKLY_DELETE_COUNT=$((WEEKLY_COUNT - WEEKLY_RETENTION_COUNT))

    echo "[INFO] Weekly backups to remove: $WEEKLY_DELETE_COUNT"
    log "Weekly backups to remove: $WEEKLY_DELETE_COUNT"

    find "$WEEKLY_ROOT" \
        -mindepth 1 \
        -maxdepth 1 \
        -type d | sort | head -n "$WEEKLY_DELETE_COUNT" |
    while read -r OLD_WEEKLY; do

        echo "[INFO] Removing old Weekly backup: $OLD_WEEKLY"
        log "Removing old Weekly backup: $OLD_WEEKLY"

        rm -rf "$OLD_WEEKLY"

    done

else

    echo "[INFO] No old Weekly backups need to be removed."
    log "No old Weekly backups need to be removed."

fi
# ---------- Result ----------

echo
echo "[SUCCESS] Backup completed successfully."
echo "[INFO] Backup location:"
echo "       $BACKUP_DIR"

log "Backup completed successfully."
log "Backup location: $BACKUP_DIR"

echo
