#!/bin/bash
#----------------------------------------------------------------------
# Config Saver
#
# Saves configuration files from the local system (~/.config) to this repository.
#----------------------------------------------------------------------

set -e

# Source helper functions
REPO_DIR_HELPER="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
HELPER_SCRIPT="$REPO_DIR_HELPER/install_modules/helpers.sh"
source "$HELPER_SCRIPT"

#-------------------------------------------------------
# Configuration
#-------------------------------------------------------
REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)/.."
CONFIGS_DIR_REPO="$REPO_DIR/configs"
CONFIGS_DIR_SYSTEM="$HOME/.config"

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

    # Using rsync is more efficient and provides better output
    rsync -av --delete "$source_dir/" "$dest_dir/"
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

    for config_app_dir in "$CONFIGS_DIR_REPO"/*; do
        if [ -d "$config_app_dir" ]; then
            config_name=$(basename "$config_app_dir")
            local system_path="$CONFIGS_DIR_SYSTEM/$config_name"
            local repo_path="$CONFIGS_DIR_REPO/$config_name"
            sync_files "$system_path" "$repo_path" "$config_name"
        fi
    done

    echo "============================================================"
    _log SUCCESS "Configuration saving finished successfully."
    echo "============================================================"
}

#-------------------------------------------------------
# Script Execution
#-------------------------------------------------------
main
