#!/bin/bash

RCLONE_LOG_FILE="$HOME/arch-setup/scripts/rclone/rclone.log"

#-------------------------------------------------------
# Main Logic
#-------------------------------------------------------
{
     echo "[$(date)] Performing a full resync..."
     rclone bisync gdrive: $HOME/GoogleDrive \
          --transfers=24 \
          --checkers=48 \
          --drive-chunk-size=64M \
          --fast-list \
          --progress \
          --drive-acknowledge-abuse \
          --resync
     echo "[$(date)] Full resync finished."

} >>"$RCLONE_LOG_FILE" 2>&1
