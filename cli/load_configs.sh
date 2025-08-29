#!/bin/bash
#----------------------------------------------------------------------
# Config Loader
#
# Loads configuration files from this repository to the local system.
#----------------------------------------------------------------------

set -e

#-------------------------------------------------------
# Configuration
#-------------------------------------------------------
# Get the directory of the current script (e.g., /home/azpepoze/az-arch-hyprland/cli)
CURRENT_SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
# Get the parent directory of the current script (e.g., /home/azpepoze/az-arch-hyprland)
REPO_DIR="$(dirname "$CURRENT_SCRIPT_DIR")"
CONFIGS_DIR_REPO="$REPO_DIR/dots"
CUSTOM_CONFIGS_DIR_REPO="$REPO_DIR/dots-custom"
CONFIGS_DIR_SYSTEM="$HOME"

# Source helper functions
HELPER_SCRIPT="$REPO_DIR/scripts/install_modules/helpers.sh"
# Check if helper script exists before sourcing
if [ -f "$HELPER_SCRIPT" ]; then
    source "$HELPER_SCRIPT"
else
    # Define a fallback _log function if helper is not found
    _log() {
        local level=$1
        shift
        # Default log to stderr to avoid issues with command substitution
        echo "[$level] $@" >&2
    }
fi

#-------------------------------------------------------
# Helper Functions
#-------------------------------------------------------
sync_files() {
    local source_dir=$1
    local dest_dir=$2
    local config_name=$3
    local exclude_path=$4 # New optional parameter

    echo "--- Loading '$config_name' ---"
    if [ ! -d "$source_dir" ]; then
        _log WARN "Source directory for '$config_name' not found at '$source_dir'. Skipping."
        return
    fi

    mkdir -p "$dest_dir"

    local rsync_args=("-av")
    if [ -n "$exclude_path" ]; then
        rsync_args+=("--exclude=$exclude_path")
    fi

    # Removed --delete flag to prevent deleting files in the destination
    rsync "${rsync_args[@]}" "$source_dir/" "$dest_dir/"
    echo "---------------------------"
}

merge_quickshell_colors() {
    echo "--- Merging QuickShell colors.json ---"

    if ! command -v jq &> /dev/null; then
        _log WARN "'jq' command not found. Cannot merge colors.json. Please install it first (e.g., 'sudo pacman -S jq'). Skipping."
        return
    fi

    local repo_colors_file="$CONFIGS_DIR_REPO/local/state/quickshell/user/generated/colors.json"
    local system_colors_file="$CONFIGS_DIR_SYSTEM/.local/state/quickshell/user/generated/colors.json"

    if [ ! -f "$repo_colors_file" ]; then
        _log WARN "Repo colors.json not found at '$repo_colors_file'. Skipping."
        return
    fi

    # Ensure destination directory exists
    mkdir -p "$(dirname "$system_colors_file")"

    if [ ! -f "$system_colors_file" ]; then
        _log INFO "No existing colors.json found at '$system_colors_file'. Copying from repo."
        cp "$repo_colors_file" "$system_colors_file"
    else
        _log INFO "Existing colors.json found. Merging with repo version."
        local temp_file
        temp_file=$(mktemp)
        # Merge system file with repo file, where the repo file (.[1]) takes precedence over the system file (.[0])
        if jq -s '[.[0] * .[1]]' "$system_colors_file" "$repo_colors_file" > "$temp_file"; then
            mv "$temp_file" "$system_colors_file"
            _log SUCCESS "Successfully merged colors.json."
        else
            _log ERROR "Failed to merge colors.json with jq."
            rm -f "$temp_file"
        fi
    fi
    echo "------------------------------------"
}

patch_quickshell_background() {
    echo "--- Patching QuickShell Background ---"
    local qml_file="$HOME/.config/quickshell/ii/modules/background/Background.qml"

    if [ -f "$qml_file" ]; then
        _log INFO "Found QuickShell Background.qml at '$qml_file'. Patching..."
        sed -i 's#visible: opacity > 0#visible: false // opacity > 0#g' "$qml_file"
        # sed -i '/clockX/s/leftMargin:.*/leftMargin: implicitWidth \/ 2/' "$qml_file"
        # sed -i '/clockY/s/topMargin:.*/topMargin: implicitHeight/' "$qml_file"
        _log SUCCESS "Successfully patched QuickShell Background.qml."
    else
        _log WARN "QuickShell Background.qml not found at '$qml_file'. Skipping patch."
    fi
    echo "------------------------------------"
}

#-------------------------------------------------------
# Load Configurations from a Source Directory
#-------------------------------------------------------
load_configs_from_source() {
    local source_dir=$1
    local label_suffix=$2 # e.g., " (custom)"

    if [ ! -d "$source_dir" ]; then
        # Don't log if it's the custom dir and it doesn't exist, as this is an expected scenario.
        if [[ ! "$label_suffix" == *"custom"* ]]; then
             _log WARN "Configuration source directory not found at '$source_dir'. Skipping."
        fi
        return
    fi

    echo "============================================================"
    echo "Loading configurations from: $source_dir"
    echo "============================================================"

    # Loop through each type of config (.config, .local, etc.)
    for config_type_dir in "$source_dir"/*; do
        if [ ! -d "$config_type_dir" ]; then
            continue
        fi

        local type_name
        type_name=$(basename "$config_type_dir") # e.g., "config" or "local"

        #-------------------------------------------------------
        # Handle .gemini folder specifically
        #-------------------------------------------------------
        if [ "$type_name" == "gemini" ]; then
            local repo_path="$config_type_dir"
            local system_path="$CONFIGS_DIR_SYSTEM/.$type_name"

            echo "--- Loading '$type_name'$label_suffix ---"
            if [ ! -d "$repo_path" ]; then
                _log WARN "Source directory for '$type_name' not found at '$repo_path'. Skipping."
                continue
            fi

            mkdir -p "$system_path"
            rsync -av --exclude="instruction.md" "$repo_path/" "$system_path/"

            if [ -f "$repo_path/instruction.md" ]; then
                cp "$repo_path/instruction.md" "$system_path/GEMINI.md"
                _log SUCCESS "Copied instruction.md${label_suffix} to $system_path/GEMINI.md"
            else
                _log WARN "instruction.md not found in $repo_path. Skipping specific copy."
            fi
            echo "---------------------------"
            continue
        fi

        #-------------------------------------------------------
        # General processing for other config types
        #-------------------------------------------------------
        for config_app_dir in "$config_type_dir"/*; do
            if [ -d "$config_app_dir" ]; then
                local app_name
                app_name=$(basename "$config_app_dir")

                local repo_path="$config_app_dir"
                local system_path="$CONFIGS_DIR_SYSTEM/.$type_name/$app_name"
                local exclude_arg=""

                # if [[ "$app_name" == "quickshell" && "$type_name" == "local" ]]; then
                #     exclude_arg="user/generated/colors.json"
                # fi

                sync_files "$repo_path" "$system_path" "$app_name$label_suffix" "$exclude_arg"
            fi
        done
    done
}

#-------------------------------------------------------
# Main Logic
#-------------------------------------------------------
main() {
    # Default values for flags
    local skip_gpu=false
    local skip_cursor=false

    # Parse command-line arguments
    for arg in "$@"; do
        case $arg in
            --skip-gpu)
            skip_gpu=true
            shift
            ;;
            --skip-cursor)
            skip_cursor=true
            shift
            ;;
        esac
    done

    # GPU Configuration
    if [ "$skip_gpu" = false ]; then
        "$CURRENT_SCRIPT_DIR/configs/gpu.sh"
    else
        _log INFO "Skipping GPU configuration due to --skip-gpu flag."
    fi

    # Cursor Theme Configuration
    if [ "$skip_cursor" = false ]; then
        "$CURRENT_SCRIPT_DIR/configs/cursor.sh"
    else
         _log INFO "Skipping cursor configuration due to --skip-cursor flag."
    fi

    # Load base and custom configurations
    load_configs_from_source "$CONFIGS_DIR_REPO" ""
    load_configs_from_source "$CUSTOM_CONFIGS_DIR_REPO" " (custom)"
    
    # Handle special cases
    # merge_quickshell_colors
    patch_quickshell_background

    _log INFO "Reloading Hyprland configuration..."
    hyprctl reload 2>/dev/null || _log WARN "Hyprland is not running. Skipping reload."

    echo "============================================================"
    _log SUCCESS "Configuration loading finished successfully."
    echo "============================================================"
}

#-------------------------------------------------------
# Script Execution
#-------------------------------------------------------
main "$@"