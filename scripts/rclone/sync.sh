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
pre_sync_check() {
     # Check for a stale lock file before running sync
     if [ -f "$LOCK_FILE_PATH" ]; then
          echo "[$(date)] [Script] Lock file found at ${LOCK_FILE_PATH}."
          # Check if an rclone process is actually running and kill it
          if pgrep -x "rclone" >/dev/null; then
               echo "[$(date)] [Script] An rclone process is currently running. Killing it to proceed with sync..."
               pkill -x "rclone"
               sleep 1 # Give it a moment to terminate
               echo "[$(date)] [Script] Old rclone process killed."
          else
               echo "[$(date)] [Script] No rclone process found, treating lock file as stale."
          fi

          # Now that any running process is killed, we can remove the stale lock file.
          echo "[$(date)] [Script] Removing stale lock file..."
          rclone deletefile "$LOCK_FILE_PATH"
          if [ $? -eq 0 ]; then
               echo "[$(date)] [Script] Stale lock file removed successfully."
          else
               echo "[$(date)] [Script] Error: Failed to remove stale lock file. Please check permissions."
               return 1 # Return 1 to indicate failure
          fi
     fi
     return 0 # Return 0 to indicate that sync can proceed
}

run_bisync() {
     # Run rclone bisync.
     # The first argument ($1) can be used for additional flags like --resync
     rclone bisync gdrive: "$WATCH_DIR" \
          --transfers=24 \
          --checkers=48 \
          --drive-chunk-size=64M \
          --fast-list \
          --drive-acknowledge-abuse \
          --progress \
          $1 # Pass the first argument as an extra flag
}

#-------------------------------------------------------
# Main Logic
#-------------------------------------------------------

#-------------------------------------------------------
# Initial Sync
#-------------------------------------------------------
echo "[$(date)] [Script] Performing initial sync on startup..."
pre_sync_check
if [ $? -eq 0 ]; then
     # Run initial sync with --resync
     run_bisync --resync
else
     echo "[$(date)] [Script] Pre-sync check failed. Initial sync skipped."
fi

#-------------------------------------------------------
# Main Loop
#-------------------------------------------------------
while true; do
     echo "[$(date)] [Script] Watching for file changes or timeout of ${REMOTE_CHECK_INTERVAL}s in ${WATCH_DIR}..."

     # Wait for file system events or timeout
     inotifywait -r -t "$REMOTE_CHECK_INTERVAL" -e create,delete,modify,move "$WATCH_DIR" 2>/dev/null
     exit_code=$?

     if [ $exit_code -eq 0 ]; then
          echo "[$(date)] [Script] Local file change detected. Starting rclone bisync..."
     elif [ $exit_code -eq 1 ]; then
          echo "[$(date)] [Script] Watched file/directory deleted. Starting rclone bisync..."
     elif [ $exit_code -eq 2 ]; then
          echo "[$(date)] [Script] Timeout reached. Starting scheduled sync to check for remote changes..."
     else
          echo "[$(date)] [Script] Warning: inotifywait exited with code ${exit_code}. Triggering sync anyway and retrying."
     fi

     # Run the pre-sync check before every sync attempt
     pre_sync_check
     if [ $? -ne 0 ]; then
          echo "[$(date)] [Script] Pre-sync check failed. Sync will be attempted on the next cycle."
     else
          # Run the sync command
          run_bisync

          # Check for an error that mentions resync
          if [ $? -ne 0 ]; then
               echo "[$(date)] [Script] Bisync aborted. Attempting to recover with --resync..."
               run_bisync --resync
               if [ $? -ne 0 ]; then
                    echo "[$(date)] [Script] Error: --resync recovery also failed. Please check output manually."
               fi
          fi
     fi

     echo "[$(date)] [Script] Sync finished. Resuming watch."
done
