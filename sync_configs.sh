#!/bin/bash

#----------------------------------------------------------------------
# Universal Config Synchronizer
#
# A smart script to synchronize configuration files between the local
# system (~/.config) and this repository.
#
# Usage:
#   ./sync_configs.sh save   - Save configs from system to the repo
#   ./sync_configs.sh load   - Load configs from the repo to the system
#
# The script automatically detects which configs to process based on
# the directory structure within the `configs` folder.
#----------------------------------------------------------------------

set -e # Exit immediately if a command exits with a non-zero status.

#-------------------------------------------------------
# Configuration
#-------------------------------------------------------
REPO_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
CONFIGS_DIR_REPO="$REPO_DIR/configs"
CONFIGS_DIR_SYSTEM="$HOME/.config"
MODE=$1

#-------------------------------------------------------
# Helper Functions
#-------------------------------------------------------
print_usage() {
    echo "Usage: $0 [save|load]"
    echo "  save: Save configurations from the system to this repository."
    echo "  load: Load configurations from this repository to the system."
}

# A function to sync files based on the given direction
# $1: Source directory
# $2: Destination directory
# $3: Name of the config being processed (for logging)
sync_files() {
    local source_dir=$1
    local dest_dir=$2
    local config_name=$3

    echo "--- Processing '$config_name' ---"
    if [ ! -d "$source_dir" ]; then
        echo "Warning: Source directory for '$config_name' not found at '$source_dir'. Skipping."
        return
    fi

    # Ensure the destination directory exists
    mkdir -p "$dest_dir"

    # Find all files in the source directory and copy them to the destination
    find "$source_dir" -type f -print0 | while IFS= read -r -d '' source_file; do
        # Calculate the relative path from the source base directory
        relative_path="${source_file#$source_dir/}"
        dest_file="$dest_dir/$relative_path"

        # Create the target directory if it doesn't exist
        mkdir -p "$(dirname "$dest_file")"

        echo "Syncing: $relative_path"
        cp -v "$source_file" "$dest_file"
    done
    echo "---------------------------"
}


#-------------------------------------------------------
# Main Logic
#-------------------------------------------------------
main() {
    if [ -z "$MODE" ]; then
        echo "Error: No mode specified."
        print_usage
        exit 1
    fi

    if [ ! -d "$CONFIGS_DIR_REPO" ]; then
        echo "Error: Repository configs directory not found at '$CONFIGS_DIR_REPO'."
        exit 1
    fi

    echo "============================================================"
    echo "Starting configuration sync in '$MODE' mode."
    echo "Repo Dir:   $CONFIGS_DIR_REPO"
    echo "System Dir: $CONFIGS_DIR_SYSTEM"
    echo "============================================================"

    # Iterate over each subdirectory in the repo's config folder (e.g., hypr, kitty)
    for config_app_dir in "$CONFIGS_DIR_REPO"/*; do
        if [ -d "$config_app_dir" ]; then
            config_name=$(basename "$config_app_dir")

            if [ "$MODE" == "save" ]; then
                # Saving from System to Repo
                local system_path="$CONFIGS_DIR_SYSTEM/$config_name"
                local repo_path="$CONFIGS_DIR_REPO/$config_name"
                sync_files "$system_path" "$repo_path" "$config_name"

            elif [ "$MODE" == "load" ]; then
                # Loading from Repo to System
                local repo_path="$CONFIGS_DIR_REPO/$config_name"
                local system_path="$CONFIGS_DIR_SYSTEM/$config_name"
                sync_files "$repo_path" "$system_path" "$config_name"
            else
                echo "Error: Invalid mode '$MODE'."
                print_usage
                exit 1
            fi
        fi
    done

    echo "============================================================"
    echo "Configuration sync finished successfully."
    echo "============================================================"
}

#-------------------------------------------------------
# Script Execution
#-------------------------------------------------------
main
