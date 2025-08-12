#!/bin/bash
#----------------------------------------------------------------------
# Config Saver
#
# Saves configuration files from the local system (~/.config) to this repository.
#----------------------------------------------------------------------

set -e

# Source helper functions
REPO_DIR_HELPER="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
HELPER_SCRIPT="$(dirname "$REPO_DIR_HELPER")/scripts/install_modules/helpers.sh"
source "$HELPER_SCRIPT"

#-------------------------------------------------------
# Configuration
#-------------------------------------------------------
# Get the directory of the current script (e.g., /home/azpepoze/az-arch-hyprland/cli)
CURRENT_SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
# Get the parent directory of the current script (e.g., /home/azpepoze/az-arch-hyprland)
REPO_DIR="$(dirname "$CURRENT_SCRIPT_DIR")"
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

        #-------------------------------------------------------
        # Handle .gemini folder specifically
        #-------------------------------------------------------
        if [ "$type_name" == "gemini" ]; then
            local repo_path="$config_type_dir" # This is dots/gemini
            local system_path="$CONFIGS_DIR_SYSTEM/.$type_name" # This is $HOME/.gemini

            echo "--- Saving '$type_name' ---"
            if [ ! -d "$system_path" ]; then
                _log WARN "Source directory for '$type_name' not found at '$system_path'. Skipping."
                continue
            fi

            mkdir -p "$repo_path"

            # Use rsync to copy all files except GEMINI.md
            rsync -avc --existing --exclude="GEMINI.md" "$system_path/" "$repo_path/"

            # Copy GEMINI.md and rename it to instruction.md at repo
            if [ -f "$system_path/GEMINI.md" ]; then
                cp "$system_path/GEMINI.md" "$repo_path/instruction.md"
                _log SUCCESS "Copied GEMINI.md to $repo_path/instruction.md"
            else
                _log WARN "GEMINI.md not found in $system_path. Skipping specific copy."
            fi
            echo "---------------------------"
        else
            #-------------------------------------------------------
            # General processing for other config types (.config, .local, etc.)
            #-------------------------------------------------------
            # Determine the system path for this config type (e.g., ~/.config or ~/.local)
            local system_config_type_dir="$CONFIGS_DIR_SYSTEM/.$type_name" # e.g., /home/azpepoze/.config or /home/azpepoze/.local

            # Loop through each specific config directory within the repo's config type directory
            for specific_config_repo_dir in "$config_type_dir"/*; do
                if [ ! -d "$specific_config_repo_dir" ]; then
                    continue
                fi

                local specific_config_name
                specific_config_name=$(basename "$specific_config_repo_dir") # e.g., "bleachbit" or "state"

                local source_path="$system_config_type_dir/$specific_config_name" # e.g., /home/azpepoze/.config/bleachbit
                local dest_path="$specific_config_repo_dir" # e.g., /home/azpepoze/az-arch-hyprland/dots/config/bleachbit

                sync_files "$source_path" "$dest_path" "$type_name/$specific_config_name"
            done
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
