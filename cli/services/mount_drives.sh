#!/bin/bash

# This script is executed by the automount.service to mount unmounted partitions.
# It is non-interactive and designed to be run in the background.

echo "🔎 [Auto-Mount Service] Checking for unmounted drives..."

# Get a list of all block devices that are partitions and are not currently mounted.
unmounted_partitions=$(lsblk -l -n -o NAME,TYPE,MOUNTPOINT | awk '$2=="part" && $3=="" {print $1}')

if [ -z "$unmounted_partitions" ]; then
    echo "✅ [Auto-Mount Service] All detected partitions are already mounted."
    exit 0
fi

# Loop through each unmounted partition and attempt to mount it using udisksctl.
for partition in $unmounted_partitions; do
    device_path="/dev/$partition"
    echo "▶️ [Auto-Mount Service] Attempting to mount $device_path..."
    udisksctl mount --block-device "$device_path" --no-user-interaction
done

echo "✅ [Auto-Mount Service] Finished mounting process."
