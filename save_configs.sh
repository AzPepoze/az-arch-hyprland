#!/bin/bash
#----------------------------------------------------------------------
# Config Saver
#
# Saves configuration files from the local system (~/.config) to this repository.
#----------------------------------------------------------------------

set -e

# Source helper functions
REPO_DIR_HELPER="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
HELPER_SCRIPT="$REPO_DIR_HELPER/scripts/install_modules/helpers.sh"
source "$HELPER_SCRIPT"

#-------------------------------------------------------
# Configuration
#-------------------------------------------------------
REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
CONFIGS_DIR_REPO="$REPO_DIR/dots"
CONFIGS_DIR_SYSTEM="$HOME"

#-------------------------------------------------------
# Helper Functions
#-------------------------------------------------------
sync_files() {
    local source_dir=$1
    local dest_dir=$2
    local config_name=$3

    echo "--- Saving '$config_name' ---"
    if [ ! -d "$source_dir" ]; then
        _log WARN "Source directory for '$config_name' not found at '$source_dir'. Skipping."
        return
    fi

    mkdir -p "$dest_dir"

    rsync -avc --existing "$source_dir/" "$dest_dir/"
    echo "---------------------------"
}

#-------------------------------------------------------
# Main Logic
#-------------------------------------------------------
main() {
    if [ ! -d "$CONFIGS_DIR_REPO" ]; then
        _log ERROR "Repository configs directory not found at '$CONFIGS_DIR_REPO'."
        exit 1
    fi

    echo "============================================================"
    echo "Saving configurations from System to Repo."
    echo "Repo Dir:   $CONFIGS_DIR_REPO"
    echo "System Dir: $CONFIGS_DIR_SYSTEM"
    echo "============================================================"

    # Loop through each type of config (.config, .local, etc.)
    for config_type_dir in "$CONFIGS_DIR_REPO"/*; do
        if [ ! -d "$config_type_dir" ]; then
            continue
        fi

        local type_name
        type_name=$(basename "$config_type_dir") # e.g., "config" or "local"

        # Loop through each application's config within the type
        for config_app_dir in "$config_type_dir"/*; do
            if [ -d "$config_app_dir" ]; then
                local app_name
                app_name=$(basename "$config_app_dir") # e.g., "hypr" or "kitty"

                local system_path="$CONFIGS_DIR_SYSTEM/.$type_name/$app_name"
                local repo_path="$config_type_dir/$app_name"

                sync_files "$system_path" "$repo_path" "$app_name"
            fi
        done
    done

    echo "============================================================"
    _log SUCCESS "Configuration saving finished successfully."
    echo "============================================================"
}

#-------------------------------------------------------
# Script Execution
#-------------------------------------------------------
main
