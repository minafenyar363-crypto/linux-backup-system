# Linux Backup System

A Bash-based Linux backup automation system designed to perform scheduled daily backups, snapshot-based backups, retention management, weekly rotation, and data restoration.

## Features

- Full backup when no previous backup exists
- Snapshot backups using `rsync` and hard links
- Daily backup retention
- Weekly backup rotation
- Weekly backup retention
- Restore backups to the original source
- Disk space validation before backup
- Logging of backup operations
- Error handling using Bash `trap`
- Configuration-driven design
- Automated execution using Cron

## Project Structure

```text
linux-backup-system/
├── backup.sh
├── restore.sh
├── config/
│   └── backup.conf
├── backups/
├── logs/
├── restore-test/
└── .gitignore

backups/, logs/, and restore-test/ are excluded from Git using .gitignore.

How It Works
Daily Backup

The system creates a new backup directory using a timestamp:

YYYY-MM-DD_HH-MM-SS

Example:

backups/daily/2026-09-06_12-40-11

If no previous backup exists, the system performs a full backup.

If a previous backup exists, the system uses rsync with:

--link-dest

This creates a snapshot-style backup where unchanged files can share the same inode through hard links, reducing unnecessary disk usage.

Each backup can still be accessed as a complete snapshot.

Daily Retention

The system keeps the configured number of daily backups.

Example:

Retention = 7

If 8 daily backups exist, the oldest backup is removed.

Weekly Rotation

Every Sunday, the system creates a weekly backup from the latest daily backup.

Weekly backups are stored separately:

backups/weekly/

Example:

backups/weekly/2026-09-06

The weekly backup is stored as an independent copy and does not use --link-dest.

The script also prevents creating multiple weekly backups for the same day.

Weekly Retention

The system keeps the configured number of weekly backups.

Example:

Weekly Retention = 4

If more than four weekly backups exist, the oldest weekly backups are removed.

Restore

A specific backup can be restored using:

./restore.sh BACKUP_DATE

Example:

./restore.sh 2026-09-06_12-40-11

The restore script:

Validates that the requested backup exists
Displays the source and target
Requests confirmation before restoring
Restores the backup using rsync

The restore operation uses:

rsync -a

to copy the backup contents back to the configured source directory.

Configuration

Backup settings are stored in:

config/backup.conf

Example:

SOURCE="$HOME/backup-test/source"
BACKUP_ROOT="$HOME/backup-project/backups/daily"
RETENTION_COUNT=7
WEEKLY_ROOT="$HOME/backup-project/backups/weekly"
WEEKLY_RETENTION_COUNT=4

The configuration file allows backup settings to be changed without modifying the main backup logic.

Logging

Backup operations are logged to:

logs/backup.log

Cron output is redirected to:

logs/cron.log

The logs include information such as:

Backup start
Source and destination
Disk space checks
Backup type
Retention actions
Weekly rotation
Errors
Successful completion
Error Handling

The scripts use:

set -euo pipefail

and Bash trap for error handling.

Errors are logged with:

Timestamp
Line number
Failed command

Example:

[ERROR] Line: 25 | Command: ...
Disk Space Check

Before starting a backup, the system compares:

Source data size
Available filesystem space

If available space is insufficient, the backup stops before starting the backup operation.

Automation

The backup system is automated using Cron.

Example Cron job:

0 2 * * * /home/mina/backup-project/backup.sh >> /home/mina/backup-project/logs/cron.log 2>&1

This runs the backup every day at 2:00 AM.

On Sunday, the backup script also performs the weekly rotation.

Backup Flow
Cron
  │
  ▼
backup.sh
  │
  ├── Load configuration
  │
  ├── Check disk space
  │
  ├── Create Daily Backup
  │
  ├── Apply Daily Retention
  │
  ├── Sunday?
  │      │
  │      └── Create Weekly Backup
  │
  ├── Apply Weekly Retention
  │
  └── Log result
Testing

The project was tested using a Linux virtual machine.

Tests included:

Full backup
Snapshot backup
Hard-link verification
Daily retention policy
Weekly rotation
Weekly retention
Restore of deleted files
Disk space validation
Error handling
Cron automation
Technologies
Linux
Bash
rsync
Cron
GNU/Linux utilities
Git / GitHub
Future Improvements

Possible future enhancements:

Remote backup using SSH and rsync
Backup integrity verification
Locking to prevent overlapping backup jobs
Notifications on backup failure
Monthly backup rotation
Systemd timer support
Author

Mina Fenyar

GitHub:

https://github.com/minafenyar363-crypto
