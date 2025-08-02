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
REMOTE_NAME="gdrive:"
REMOTE_CHECK_INTERVAL=60

#-------------------------------------------------------
# Functions
#-------------------------------------------------------
check_for_running_process() {
     if pgrep -x "rclone" >/dev/null; then
          _log WARN "An rclone process is already running. Killing it to prevent conflicts..."
          pkill -x "rclone"
          sleep 1 # Give it a moment to die
          _log INFO "Old rclone process killed."
     fi
}

run_safe_sync() {
     _log INFO "Starting safe sync process..."

     # Step 1: Push local changes to remote
     # Only copies files from local if they are newer than remote
     _log INFO "[PUSH] Uploading local changes to ${REMOTE_NAME}..."
     rclone sync "$WATCH_DIR" "$REMOTE_NAME" \
          --update \
          --transfers=24 \
          --checkers=48 \
          --drive-chunk-size=64M \
          --fast-list \
          --drive-acknowledge-abuse \
          --progress \
          --exclude "node_modules/**"

     if [ $? -ne 0 ]; then
          _log ERROR "[PUSH] Failed to sync local changes to remote. Aborting pull step."
          return 1
     fi

     # Step 2: Pull remote changes to local
     # Only copies files from remote if they are newer than local
     _log INFO "[PULL] Downloading remote changes from ${REMOTE_NAME}..."
     rclone sync "$REMOTE_NAME" "$WATCH_DIR" \
          --update \
          --transfers=24 \
          --checkers=48 \
          --drive-chunk-size=64M \
          --fast-list \
          --drive-acknowledge-abuse \
          --progress \
          --exclude "node_modules/**"

     if [ $? -ne 0 ]; then
          _log ERROR "[PULL] Failed to sync remote changes to local."
          return 1
     fi

     _log SUCCESS "Safe sync completed successfully."
     return 0
}

#-------------------------------------------------------
# Main Logic
#-------------------------------------------------------

#-------------------------------------------------------
# Initial Sync
#-------------------------------------------------------
_log INFO "Performing initial sync on startup..."
check_for_running_process
run_safe_sync

#-------------------------------------------------------
# Main Loop
#-------------------------------------------------------
while true; do
     _log INFO "Watching for file changes or timeout of ${REMOTE_CHECK_INTERVAL}s in ${WATCH_DIR}..."

     inotifywait -r -t "$REMOTE_CHECK_INTERVAL" -e create,delete,modify,move "$WATCH_DIR" 2>/dev/null
     exit_code=$?

     case $exit_code in
          0)
               _log INFO "Local file change detected. Starting rclone safe sync..."
               ;;
          1)
               _log INFO "Watched file/directory deleted. Starting rclone safe sync..."
               ;;
          2)
               _log INFO "Timeout reached. Starting scheduled sync to check for remote changes..."
               ;;
          *)
               _log WARN "inotifywait exited with code ${exit_code}. Triggering sync anyway and retrying."
               ;;
     esac

     check_for_running_process
     run_safe_sync

     _log INFO "Sync finished. Resuming watch."
done
