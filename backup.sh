#!/bin/bash
########################################
# Remote Backup Script
# Usage: ./backup.sh <config_file> [--dry-run]
########################################

NOTIFY_SCRIPT="/usr/local/emhttp/webGui/scripts/notify"
DRY_RUN=false


if [[ -z "$1" || "$1" == "--help" ]]; then
    echo "Usage: $0 <config_file> [--dry-run]"
    exit 1
fi

config_file="$1"

if [[ "$2" == "--dry-run" ]]; then
    DRY_RUN=true
    echo "- DRY RUN ENABLED - No actual data will be transferred or modified."
fi

notify_backup_result() {
    local status="$1"
    local message
    local icon

    if [[ "$status" -ne 0 ]]; then
        message="Backup Failed"
        icon="alert"
    else
        message="Backup Completed"
        icon="normal"
    fi

    "$NOTIFY_SCRIPT" -e "Remote Server Backup" -s "${config[NAME]}" -d "$message" -i "$icon"
}

########################################
# Verify and load config
########################################
if [[ ! -s "$config_file" ]]; then
    echo "Error: Missing or empty config file ($config_file)"
    notify_backup_result 1
    exit 1
fi

declare -A config
while IFS='=' read -r key value; do
    [[ -z "$key" || "$key" =~ ^# ]] && continue
    config["$key"]="$value"
done < "$config_file"

########################################
# Setup Backup Paths
########################################
backup_base="${config[DEST]}/${config[NETWORK]}/${config[NAME]}"
daily_dir="$backup_base/Daily"
weekly_dir="$backup_base/Weekly"
monthly_dir="$backup_base/Monthly"

########################################
# Daily Backup
########################################
if [[ "$DRY_RUN" == true ]]; then
    echo "- DRY RUN - Would make \"$daily_dir\""
    echo "- DRY RUN - Would sync from remote to \"$daily_dir/\""
    rsync_opts="-aHAXx --delete --dry-run"
else
    mkdir -p "$daily_dir"
    rsync_opts="-aHAXx --delete"
fi

rsync $rsync_opts "${config[OPTIONS]}" -e "/usr/bin/ssh -o Compression=no -x -p \"${config[PORT]}\" -i \"${config[SSHKEY]}\"" \
    "root@${config[REMOTE_IP]}:${config[SOURCE]}" "$daily_dir/" 2>&1

status=$?
notify_backup_result "$status"
[[ "$status" -ne 0 ]] && exit 1

########################################
# Weekly Sunday Backup
########################################
if [[ "$(date +%a)" == "Sun" ]]; then
    if [[ "$DRY_RUN" == true ]]; then
        echo "- DRY RUN - Would make \"$weekly_dir\""
        echo "- DRY RUN - Would sync: \"$daily_dir/\" -> \"$weekly_dir/\""
        rsync_opts="-aHAXx --delete --dry-run"
    else
        mkdir -p "$weekly_dir"
        rsync_opts="-aHAXx --delete"
    fi

    rsync $rsync_opts "$daily_dir/" "$weekly_dir/" 2>&1

    status=$?
    notify_backup_result "$status"
    [[ "$status" -ne 0 ]] && exit 1
fi

########################################
# Monthly Backup
########################################
if [[ "$(date +%d)" == "01" ]]; then
    mkdir -p "$monthly_dir"
    tar_file="$monthly_dir/${config[NAME]}_$(date +%B-%Y).tar.gz"

    if [[ "$DRY_RUN" == true ]]; then
        echo "- DRY RUN - Would make \"$monthly_dir\""
        echo "- DRY RUN - Would create archive: \"$tar_file\""
    else
        echo "- Creating monthly archive at \"$tar_file\""
        tar -czPf "$tar_file" "$daily_dir" 2>&1
        status=$?
        if [[ "$status" -ne 0 ]]; then
            echo "[!] tar failed"
            notify_backup_result 1
            exit 1
        fi

        echo "- Generating checksum"
        md5sum "$tar_file" > "$tar_file".md5
        notify_backup_result 0
    fi
fi
