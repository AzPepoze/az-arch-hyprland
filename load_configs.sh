#!/bin/bash
#----------------------------------------------------------------------
# Config Loader
#
# Loads configuration files from this repository to the local system.
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
CONFIGS_DIR_REPO="$REPO_DIR/configs"
CONFIGS_DIR_SYSTEM="$HOME/.config"
SETTINGS_FILE="$REPO_DIR/settings/config.json"

#-------------------------------------------------------
# Helper Functions
#-------------------------------------------------------
sync_files() {
    local source_dir=$1
    local dest_dir=$2
    local config_name=$3

    echo "--- Loading '$config_name' ---"
    if [ ! -d "$source_dir" ]; then
        _log WARN "Source directory for '$config_name' not found at '$source_dir'. Skipping."
        return
    fi

    mkdir -p "$dest_dir"

    rsync -av "$source_dir/" "$dest_dir/"
    echo "---------------------------"
}

configure_gpu_device() {
    echo "Detecting available GPUs..." >&2

    if ! command -v lspci &>/dev/null; then
        _log ERROR "lspci command not found. Please install pciutils." >&2
        exit 1
    fi

    declare -A lspci_line_to_device_path
    local menu_options=()

    while read -r line; do
        local pci_addr
        pci_addr=$(echo "$line" | awk '{print $1}')
        local symlink_path="/dev/dri/by-path/pci-0000:${pci_addr}-card"

        if [ -L "$symlink_path" ]; then
            local device_path
            device_path=$(readlink -f "$symlink_path")
            lspci_line_to_device_path["$line"]="$device_path"
            menu_options+=("$line")
        fi
    done <<< "$(lspci -d ::03xx)"

    if [ ${#menu_options[@]} -eq 0 ]; then
        echo "No display controllers found. Skipping GPU configuration." >&2
        return
    fi

    menu_options+=("Exit")
    echo "Please select the primary GPU for Hyprland:" >&2
    select selected_lspci_line in "${menu_options[@]}"; do
        if [[ "$selected_lspci_line" == "Exit" ]]; then
            echo "Exiting GPU configuration." >&2
            break
        elif [[ -n "$selected_lspci_line" ]]; then
            local selected_gpu_path=${lspci_line_to_device_path["$selected_lspci_line"]}
            echo "You selected: $selected_lspci_line" >&2

            local ordered_devices=("$selected_gpu_path")
            for device in "${lspci_line_to_device_path[@]}"; do
                if [[ "$device" != "$selected_gpu_path" ]]; then
                    ordered_devices+=("$device")
                fi
            done

            local final_device_string
            final_device_string=$(printf "%s:" "${ordered_devices[@]}")
            final_device_string=${final_device_string%:}
            
            echo "$final_device_string"
            break
        else
            _log ERROR "Invalid selection. Please try again." >&2
        fi
    done
}

update_hyprland_env() {
    local gpu_device=$1

    if [ -z "$gpu_device" ]; then
        _log WARN "No GPU device provided. Skipping Hyprland env configuration."
        return
    fi

    local env_var_line="env = WLR_DRM_DEVICES,$gpu_device"
    local env_conf_file="$CONFIGS_DIR_SYSTEM/hypr/custom/env.conf"

    mkdir -p "$(dirname "$env_conf_file")"

    if [ -f "$env_conf_file" ]; then
        sed -i '/^env = WLR_DRM_DEVICES/d' "$env_conf_file"
    fi
    
    echo "Adding '$env_var_line' to $env_conf_file"
    echo "$env_var_line" >> "$env_conf_file"
}

configure_cursor_theme() {
    echo "Starting Cursor Theme Installation..."

    local built_themes_dir="$REPO_DIR/dist/cursors"
    local user_icon_dir="$HOME/.local/share/icons"

    if [ ! -d "$built_themes_dir" ] || [ -z "$(ls -A "$built_themes_dir")" ]; then
        _log ERROR "Built cursor themes not found in '$built_themes_dir'."
        echo "Please run the './build_cursors.sh' script from the project root first."
        return 1
    fi

    mapfile -t themes < <(find "$built_themes_dir" -maxdepth 1 -mindepth 1 -type d -exec basename {} \;)
    if [ ${#themes[@]} -eq 0 ]; then
        _log ERROR "No themes found in '$built_themes_dir'."
        return 1
    fi

    themes+=("Exit")

    echo "Select the cursor theme to install:"
    select theme_name in "${themes[@]}"; do
        case "$theme_name" in
            "Exit")
                echo "Exiting without installation."
                return 0
                ;;
            *)
                if [[ " ${themes[*]} " =~ " ${theme_name} " ]]; then
                    echo "Installing theme: $theme_name"

                    mkdir -p "$user_icon_dir"
                    echo "Ensured icon directory exists at '$user_icon_dir'"

                    cp -r "$built_themes_dir/$theme_name" "$user_icon_dir/"
                    _log SUCCESS "Copied '$theme_name' to '$user_icon_dir'"

                    local temp_json
                    temp_json=$(jq --arg theme "$theme_name" '.cursor.theme = $theme' "$SETTINGS_FILE")
                    echo "$temp_json" > "$SETTINGS_FILE"
                    _log SUCCESS "Updated cursor theme in config file."

                    break
                else
                    _log ERROR "Invalid option '$REPLY'. Please try again."
                fi
                ;;
        esac
    done
}

#-------------------------------------------------------
# Main Logic
#-------------------------------------------------------
main() {
    if ! command -v jq &> /dev/null; then
        _log ERROR "jq command not found. Please install jq."
        exit 1
    fi

    if [ ! -f "$SETTINGS_FILE" ]; then
        echo "Settings file not found. Creating one."
        echo '{ "cursor": { "theme": null, "size": 24 } }' > "$SETTINGS_FILE"
    fi

    local selected_gpu_device
    selected_gpu_device=$(configure_gpu_device)

    local cursor_theme
    cursor_theme=$(jq -r '.cursor.theme // empty' "$SETTINGS_FILE")

    if [ -z "$cursor_theme" ]; then
        configure_cursor_theme
    fi

    if [ ! -d "$CONFIGS_DIR_REPO" ]; then
        _log ERROR "Repository configs directory not found at '$CONFIGS_DIR_REPO'."
        exit 1
    fi

    echo "============================================================"
    echo "Loading configurations from Repo to System."
    echo "Repo Dir:   $CONFIGS_DIR_REPO"
    echo "System Dir: $CONFIGS_DIR_SYSTEM"
    echo "============================================================"

    for config_app_dir in "$CONFIGS_DIR_REPO"/*; do
        if [ -d "$config_app_dir" ]; then
            config_name=$(basename "$config_app_dir")
            local repo_path="$CONFIGS_DIR_REPO/$config_name"
            local system_path="$CONFIGS_DIR_SYSTEM/$config_name"
            sync_files "$repo_path" "$system_path" "$config_name"
        fi
    done

    if [ -n "$selected_gpu_device" ]; then
        update_hyprland_env "$selected_gpu_device"
    fi

    echo "============================================================"
    _log SUCCESS "Configuration loading finished successfully."
    echo "============================================================"
}

#-------------------------------------------------------
# Script Execution
#-------------------------------------------------------
main