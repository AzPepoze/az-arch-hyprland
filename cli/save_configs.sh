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


# This function will sync a single file or directory
sync_file_or_dir() {
    local system_source_path=$1
    local repo_dest_path=$2
    local item_name=$3 # For logging

    echo "--- Saving '$item_name' ---"
    if [ ! -e "$system_source_path" ]; then # Use -e for file or directory existence
        _log WARN "Source item for '$item_name' not found at '$system_source_path'. Skipping."
        return
    fi

    # Determine if sudo is needed
    local use_sudo=""
    if [[ "$system_source_path" == "/etc"* ]]; then
        use_sudo="sudo"
        _log INFO "Using sudo for operations on $system_source_path"
    fi

    # Ensure the destination directory exists in the repo
    $use_sudo mkdir -p "$(dirname "$repo_dest_path")" # sudo for mkdir if parent is /etc

    # Use rsync to copy the specific item
    # If it's a directory, add a trailing slash to source_path to copy contents
    if [ -d "$system_source_path" ]; then
        $use_sudo rsync -avc --existing "$system_source_path/" "$repo_dest_path/"
    else
        $use_sudo rsync -avc --existing "$system_source_path" "$repo_dest_path"
    fi
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

    # Loop through each top-level directory in 'dots' (e.g., 'home', 'etc')
    for base_type_dir in "$CONFIGS_DIR_REPO"/*; do
        if [ ! -d "$base_type_dir" ]; then
            continue
        fi

        local base_type_name
        base_type_name=$(basename "$base_type_dir") # e.g., "home" or "etc"

        local system_base_path=""
        case "$base_type_name" in
            "home")
                system_base_path="$HOME"
                ;;
            "etc")
                system_base_path="/etc"
                ;;
            *)
                _log WARN "Unknown base configuration type '$base_type_name'. Skipping."
                continue
                ;;
        esac

        # Now loop through the actual config directories/files within 'home' or 'etc' in the REPO
        # This loop will iterate over items like dots/home/config, dots/home/local, dots/etc/power-options
        for repo_item_path in "$base_type_dir"/*; do
            if [ ! -e "$repo_item_path" ]; then # Use -e for file or directory existence
                continue
            fi

            local item_name
            item_name=$(basename "$repo_item_path") # e.g., "config", "local", "power-options", "gemini"

            local system_source_prefix="" # The prefix on the system side
            local repo_dest_prefix="$repo_item_path" # The prefix on the repo side

            # Special handling for .gemini folder (which is under home/gemini)
            if [ "$base_type_name" == "home" ] && [ "$item_name" == "gemini" ]; then
                system_source_prefix="$system_base_path/.gemini"
                local repo_gemini_dir="$repo_item_path" # dots/home/gemini

                echo "--- Saving '.gemini' ---"
                if [ ! -d "$system_source_prefix" ]; then
                    _log WARN "Source directory for '.gemini' not found at '$system_source_prefix'. Skipping."
                    continue
                fi

                mkdir -p "$repo_gemini_dir"

                # Sync all files except GEMINI.md from system to repo
                rsync -avc --existing --exclude="GEMINI.md" "$system_source_prefix/" "$repo_gemini_dir/"

                # Copy GEMINI.md and rename it to instruction.md at repo
                if [ -f "$system_source_prefix/GEMINI.md" ]; then
                    cp "$system_source_prefix/GEMINI.md" "$repo_gemini_dir/instruction.md"
                    _log SUCCESS "Copied GEMINI.md to $repo_gemini_dir/instruction.md"
                else
                    _log WARN "GEMINI.md not found in $system_source_prefix. Skipping specific copy."
                fi
                echo "---------------------------"
                continue # Skip general sync_file_or_dir for gemini
            fi

            # For other configurations, determine the system source prefix
            if [ "$base_type_name" == "home" ]; then
                system_source_prefix="$system_base_path/.$item_name" # e.g., $HOME/.config, $HOME/.local
            elif [ "$base_type_name" == "etc" ]; then
                system_source_prefix="$system_base_path/$item_name" # e.g., /etc/power-options
            fi

            # Now, iterate through the actual files/directories *within* the repo's config directory
            # and sync them individually. This ensures we only save what's already in the repo.
            for repo_sub_item_path in "$repo_item_path"/*; do
                if [ ! -e "$repo_sub_item_path" ]; then
                    continue
                fi

                local sub_item_name
                sub_item_name=$(basename "$repo_sub_item_path")

                local system_source_full_path="$system_source_prefix/$sub_item_name"
                local repo_dest_full_path="$repo_sub_item_path"

                sync_file_or_dir "$system_source_full_path" "$repo_dest_full_path" "$base_type_name/$item_name/$sub_item_name"
            done
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
