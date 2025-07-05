#!/bin/bash

#-------------------------------------------------------
# Prerequisite Check
#-------------------------------------------------------
if ! command -v inotifywait &>/dev/null; then
     echo "Error: inotify-tools is not installed. Please install it to use this script." >&2
     echo "On Arch Linux, you can install it with: sudo pacman -S inotify-tools" >&2
     exit 1
fi

#-------------------------------------------------------
# Configuration
#-------------------------------------------------------
WATCH_DIR="$HOME/GoogleDrive"
REMOTE_CHECK_INTERVAL=60
LOCK_FILE_PATH="$HOME/.cache/rclone/bisync/gdrive_..home_${USER}_GoogleDrive.lck"

#-------------------------------------------------------
# Functions
#-------------------------------------------------------
log_message() {
    echo "[$(date)] [Script] $1"
}

pre_sync_check() {
     if [ -f "$LOCK_FILE_PATH" ]; then
          log_message "Lock file found at ${LOCK_FILE_PATH}."
          if pgrep -x "rclone" >/dev/null; then
               log_message "An rclone process is currently running. Killing it to proceed with sync..."
               pkill -x "rclone"
               sleep 1
               log_message "Old rclone process killed."
          else
               log_message "No rclone process found, treating lock file as stale."
          fi

          log_message "Removing stale lock file..."
          rm -f "$LOCK_FILE_PATH"
          if [ $? -eq 0 ]; then
               log_message "Stale lock file removed successfully."
          else
               log_message "Error: Failed to remove stale lock file with rm -f. Please check permissions."
               return 1
          fi
     fi
     return 0
}

run_bisync() {
     rclone bisync gdrive: "$WATCH_DIR" \
          --transfers=24 \
          --checkers=48 \
          --drive-chunk-size=64M \
          --fast-list \
          --drive-acknowledge-abuse \
          --progress \
          $1
}

#-------------------------------------------------------
# Main Logic
#-------------------------------------------------------

#-------------------------------------------------------
# Initial Sync
#-------------------------------------------------------
log_message "Performing initial sync on startup..."
if pre_sync_check; then
     run_bisync --resync
else
     log_message "Pre-sync check failed. Initial sync skipped."
fi

#-------------------------------------------------------
# Main Loop
#-------------------------------------------------------
while true; do
     log_message "Watching for file changes or timeout of ${REMOTE_CHECK_INTERVAL}s in ${WATCH_DIR}..."

     inotifywait -r -t "$REMOTE_CHECK_INTERVAL" -e create,delete,modify,move "$WATCH_DIR" 2>/dev/null
     exit_code=$?

     case $exit_code in
          0)
               log_message "Local file change detected. Starting rclone bisync..."
               ;;
          1)
               log_message "Watched file/directory deleted. Starting rclone bisync..."
               ;;
          2)
               log_message "Timeout reached. Starting scheduled sync to check for remote changes..."
               ;;
          *)
               log_message "Warning: inotifywait exited with code ${exit_code}. Triggering sync anyway and retrying."
               ;;
     esac

     if pre_sync_check; then
          run_bisync

          if [ $? -ne 0 ]; then
               log_message "Bisync aborted. Attempting to recover with --resync..."
               run_bisync --resync || log_message "Error: --resync recovery also failed. Please check output manually."
          fi
     else
          log_message "Pre-sync check failed. Sync will be attempted on the next cycle."
     fi

     log_message "Sync finished. Resuming watch."
done