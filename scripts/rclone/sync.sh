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
RCLONE_LOG_FILE="$HOME/arch-setup/scripts/rclone/rclone.log"
WATCH_DIR="$HOME/GoogleDrive"
REMOTE_CHECK_INTERVAL=60
LOCK_FILE_PATH="$HOME/.cache/rclone/bisync/gdrive_..home_${USER}_GoogleDrive.lck"

#-------------------------------------------------------
# Functions
#-------------------------------------------------------
pre_sync_check() {
     # Check for a stale lock file before running sync
     if [ -f "$LOCK_FILE_PATH" ]; then
          echo "[$(date)] Lock file found at ${LOCK_FILE_PATH}."
          # Check if an rclone process is actually running
          if pgrep -x "rclone" >/dev/null; then
               echo "[$(date)] An rclone process is currently running. Skipping sync to avoid conflict."
               return 1 # Return 1 to indicate that sync should be skipped
          else
               echo "[$(date)] No rclone process found. Removing stale lock file..."
               rm -f "$LOCK_FILE_PATH"
               if [ $? -eq 0 ]; then
                    echo "[$(date)] Stale lock file removed successfully."
               else
                    echo "[$(date)] Error: Failed to remove stale lock file. Please check permissions." >&2
                    return 1 # Return 1 to indicate failure
               fi
          fi
     fi
     return 0 # Return 0 to indicate that sync can proceed
}

run_bisync() {
     # Run rclone bisync, logging directly to the specified file
     # The first argument ($1) can be used for additional flags like --resync
     rclone bisync gdrive: "$WATCH_DIR" \
          --transfers=24 \
          --checkers=48 \
          --drive-chunk-size=64M \
          --fast-list \
          --drive-acknowledge-abuse \
          $1 # Pass the first argument as an extra flag
}

#-------------------------------------------------------
# Main Logic
#-------------------------------------------------------

# Ensure log file directory exists
mkdir -p "$(dirname "$RCLONE_LOG_FILE")"

#-------------------------------------------------------
# Initial Sync
#-------------------------------------------------------
echo "[$(date)] Performing initial sync on startup..."
pre_sync_check
if [ $? -eq 0 ]; then
     run_bisync --resync
else
     echo "[$(date)] Pre-sync check failed. Initial sync skipped."
fi

#-------------------------------------------------------
# Main Loop
#-------------------------------------------------------
while true; do
     echo "[$(date)] Watching for file changes or timeout of ${REMOTE_CHECK_INTERVAL}s in ${WATCH_DIR}..."

     # Wait for file system events or timeout
     inotifywait -r -t "$REMOTE_CHECK_INTERVAL" -e create,delete,modify,move "$WATCH_DIR" 2>/dev/null
     exit_code=$?

     if [ $exit_code -eq 0 ]; then
          echo "[$(date)] Local file change detected. Starting rclone bisync..."
     elif [ $exit_code -eq 1 ]; then
          echo "[$(date)] Watched file/directory deleted. Starting rclone bisync..."
     elif [ $exit_code -eq 2 ]; then
          echo "[$(date)] Timeout reached. Starting scheduled sync to check for remote changes..."
     else
          echo "[$(date)] Warning: inotifywait exited with code ${exit_code}. Triggering sync anyway and retrying."
     fi

     # Run the pre-sync check before every sync attempt
     pre_sync_check
     if [ $? -ne 0 ]; then
          echo "[$(date)] Pre-sync check failed. Sync will be attempted on the next cycle."
     else
          # Run the sync command. Rclone will handle the logging.
          run_bisync
          sync_exit_code=$?

          # Check for the specific error requiring --resync by inspecting the log file
          if [ $sync_exit_code -ne 0 ] && grep -q "bisync: Must run --resync to recover" "$RCLONE_LOG_FILE"; then
               echo "[$(date)] Bisync aborted. Attempting to recover with --resync..."
               run_bisync --resync
          fi
     fi

     echo "[$(date)] Sync finished. Resuming watch."
done | tee -a "$RCLONE_LOG_FILE"
