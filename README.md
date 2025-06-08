# Remote Backup Script

This Bash script provides an automated solution for performing remote backups over SSH using `rsync`, with daily, weekly, and monthly rotation policies. The script supports a dry-run mode for safe testing and provides notifications upon backup completion or failure.

## Features

- **Remote backup via SSH using `rsync`**
- **Configurable via a simple key-value config file**
- **Daily, weekly, and monthly backup rotation**
- **Notification support using a notification script**
- **Dry-run mode for safe testing**

## Requirements

- Bash (version 4 or higher recommended)
- `rsync`
- `ssh`
- `tar`
- `md5sum`

## Usage

```sh
./backup.sh <config_file> [--dry-run]
```

- `<config_file>`: Path to the configuration file describing remote and backup options.
- `--dry-run`: (Optional) Show what the script would do without making any changes.

## How It Works

1. **Daily Backup:**
   - Syncs remote directory to a local daily backup directory using `rsync`.
   - Notifies of success or failure.

2. **Weekly Backup (Sunday):**
   - Copies the daily backup to a weekly directory every Sunday.
   - Notifies of success or failure.

3. **Monthly Backup (1st of each month):**
   - Archives the daily backup to a compressed tarball in the monthly directory.
   - Generates an MD5 checksum for the archive.
   - Notifies of success or failure.

4. **Dry Run:**
   - If `--dry-run` is specified, the script prints intended actions without making changes.


## Customization

- Modify the notification script path if your system uses a different notification mechanism.
- Add or adjust `rsync` and `tar` options in the script or config file as needed.
