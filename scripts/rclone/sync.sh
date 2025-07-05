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

#-------------------------------------------------------
# Functions
#-------------------------------------------------------
run_bisync() {
     # Run rclone bisync with all specified arguments
     # The first argument ($1) can be used for additional flags like --resync
     rclone bisync gdrive: "$WATCH_DIR" \
          --transfers=24 \
          --checkers=48 \
          --drive-chunk-size=64M \
          --fast-list \
          --progress \
          --drive-acknowledge-abuse \
          $1 # Pass the first argument as an extra flag
}

#-------------------------------------------------------
# Main Logging Block
#-------------------------------------------------------
{
     #-------------------------------------------------------
     # Initial Sync
     #-------------------------------------------------------
     echo "[$(date)] Performing initial sync on startup..."
     run_bisync --resync

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

          # Run the sync command and capture output
          sync_output=$(run_bisync 2>&1)
          sync_exit_code=$?

          # Check for the specific error requiring --resync
          if [ $sync_exit_code -ne 0 ] && echo "$sync_output" | grep -q "Must run --resync to recover"; then
               echo "[$(date)] Bisync aborted. Attempting to recover with --resync..."
               run_bisync --resync
          fi

          echo "[$(date)] Sync finished. Resuming watch."
     done

}
