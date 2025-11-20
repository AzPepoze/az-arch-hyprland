#!/bin/bash

# This script is executed by the automount.service to mount unmounted partitions.
# It is non-interactive and designed to be run in the background.

echo "🔎 [Auto-Mount Service] Checking for unmounted drives..."

# If running with sudo, use the original user's name. Otherwise, use the current user.
TARGET_USER=${SUDO_USER:-$USER}

# Get the user's details.
TARGET_UID=$(id -u "$TARGET_USER")
TARGET_GID=$(id -g "$TARGET_USER")

if [ -z "$TARGET_USER" ] || [ -z "$TARGET_UID" ] || [ -z "$TARGET_GID" ]; then
    echo "❌ [Auto-Mount Service] Could not determine target user. Exiting." >&2
    exit 1
fi

# Get a list of all block devices that are partitions and are not currently mounted.
unmounted_partitions=$(lsblk -l -n -o NAME,TYPE,MOUNTPOINT | awk '$2=="part" && $3=="" {print $1}')

if [ -z "$unmounted_partitions" ]; then
    echo "✅ [Auto-Mount Service] All detected partitions are already mounted."
    exit 0
fi

# Loop through each unmounted partition and attempt to mount it.
for partition in $unmounted_partitions; do
    device_path="/dev/$partition"

    # Get label and UUID for the partition. Fallback to partition name.
    # The 'xargs' command trims leading/trailing whitespace from the output.
    label=$(lsblk -n -o LABEL "$device_path" | xargs)
    uuid=$(lsblk -n -o UUID "$device_path" | xargs)

    if [ -n "$label" ]; then
        mount_name="$label"
    elif [ -n "$uuid" ]; then
        mount_name="$uuid"
    else
        mount_name="$partition"
    fi

    # Sanitize mount_name to remove/replace characters that are invalid in filenames.
    # This replaces slashes with underscores.
    mount_name=$(echo "$mount_name" | sed 's/\//_/g')
    
    mount_point="/run/media/$TARGET_USER/$mount_name"

    echo "▶️ [Auto-Mount Service] Attempting to mount $device_path to $mount_point..."

    # Create the mount point directory if it doesn't exist.
    # This script must be run with root privileges (e.g., via sudo) to perform mount operations.
    sudo mkdir -p "$mount_point"

    # Mount the device. The filesystem type is auto-detected.
    if sudo mount "$device_path" "$mount_point"; then
        # Change ownership of the mount point to the target user for access.
        sudo chown "$TARGET_UID:$TARGET_GID" "$mount_point"
        echo "✅ [Auto-Mount Service] Successfully mounted $device_path to $mount_point"
    else
        echo "❌ [Auto-Mount Service] Failed to mount $device_path. Check dmesg for errors." >&2
        # Clean up the created directory if mount fails.
        sudo rmdir "$mount_point" 2>/dev/null
    fi
done

echo "✅ [Auto-Mount Service] Finished mounting process."
