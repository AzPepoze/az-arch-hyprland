#!/bin/bash

#-------------------------------------------------------
# Prerequisite Check
#-------------------------------------------------------
# Source helper functions
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$DIR/../.."
HELPER_SCRIPT="$PROJECT_ROOT/scripts/install_modules/helpers.sh"
source "$HELPER_SCRIPT"

if ! command -v inotifywait &>/dev/null; then
     _log ERROR "inotify-tools is not installed. Please install it to use this script."
     _log INFO "On Arch Linux, you can install it with: sudo pacman -S inotify-tools"
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
# log_message() {
#     echo "[$(date)] [Script] $1"
# } # Removed as _log will be used instead

pre_sync_check() {
     if [ -f "$LOCK_FILE_PATH" ]; then
          _log INFO "Lock file found at ${LOCK_FILE_PATH}."
          if pgrep -x "rclone" >/dev/null; then
               _log INFO "An rclone process is currently running. Killing it to proceed with sync..."
               pkill -x "rclone"
               sleep 1
               _log INFO "Old rclone process killed."
          else
               _log INFO "No rclone process found, treating lock file as stale."
          fi

          _log INFO "Removing stale lock file..."
          rm -f "$LOCK_FILE_PATH"
          if [ $? -eq 0 ]; then
               _log SUCCESS "Stale lock file removed successfully."
          else
               _log ERROR "Failed to remove stale lock file with rm -f. Please check permissions."
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
          --exclude "node_modules/**" \
          $1
}

#-------------------------------------------------------
# Main Logic
#-------------------------------------------------------

#-------------------------------------------------------
# Initial Sync
#-------------------------------------------------------
_log INFO "Performing initial sync on startup..."
if pre_sync_check; then
     run_bisync --resync
else
     _log INFO "Pre-sync check failed. Initial sync skipped."
fi

#-------------------------------------------------------
# Main Loop
#-------------------------------------------------------
while true; do
     _log INFO "Watching for file changes or timeout of ${REMOTE_CHECK_INTERVAL}s in ${WATCH_DIR}..."

     inotifywait -r -t "$REMOTE_CHECK_INTERVAL" -e create,delete,modify,move "$WATCH_DIR" 2>/dev/null
     exit_code=$?

     case $exit_code in
          0)
               _log INFO "Local file change detected. Starting rclone bisync..."
               ;;
          1)
               _log INFO "Watched file/directory deleted. Starting rclone bisync..."
               ;;
          2)
               _log INFO "Timeout reached. Starting scheduled sync to check for remote changes..."
               ;;
          *)
               _log WARN "inotifywait exited with code ${exit_code}. Triggering sync anyway and retrying."
               ;;
     esac

     if pre_sync_check; then
          run_bisync

          if [ $? -ne 0 ]; then
               _log WARN "Bisync aborted. Attempting to recover with --resync..."
               run_bisync --resync || _log ERROR "--resync recovery also failed. Please check output manually."
          fi
     else
          _log INFO "Pre-sync check failed. Sync will be attempted on the next cycle."
     fi

     _log INFO "Sync finished. Resuming watch."
done