#!/bin/bash
# Performs a full resync with rclone bisync.
# The --resync flag forces a full comparison of all files.

RCLONE_LOG_FILE="/home/azpepoze/arch-setup/scripts/rclone/rclone.log"

rclone bisync gdrive: ~/GoogleDrive \
    --transfers=24 \
    --checkers=48 \
    --drive-chunk-size=64M \
    --fast-list \
    --progress \
    --drive-acknowledge-abuse \
    --resync \
    --log-file="$RCLONE_LOG_FILE"

