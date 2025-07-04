#!/bin/bash
# Performs a normal rclone bisync.
# This relies on listings from the last run for faster execution.

RCLONE_LOG_FILE="~/arch-setup/scripts/rclone/rclone.log"

rclone bisync gdrive: ~/GoogleDrive \
     --transfers=24 \
     --checkers=48 \
     --drive-chunk-size=64M \
     --fast-list \
     --progress \
     --drive-acknowledge-abuse \
     --log-file="$RCLONE_LOG_FILE"
