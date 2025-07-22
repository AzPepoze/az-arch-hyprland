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

set -e

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

sync_files() {
    local source_dir=$1
    local dest_dir=$2
    local config_name=$3

    echo "--- Processing '$config_name' ---"
    if [ ! -d "$source_dir" ]; then
        echo "Warning: Source directory for '$config_name' not found at '$source_dir'. Skipping."
        return
    fi

    mkdir -p "$dest_dir"

    find "$source_dir" -type f -print0 | while IFS= read -r -d '' source_file; do
        relative_path="${source_file#$source_dir/}"
        dest_file="$dest_dir/$relative_path"

        mkdir -p "$(dirname "$dest_file")"

        echo "Syncing: $relative_path"
        cp -v "$source_file" "$dest_file"
    done
    echo "---------------------------"
}

configure_gpu_device() {
    echo "Detecting available GPUs..."

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
        echo "No display controllers found with a corresponding device in /dev/dri/by-path. Skipping GPU configuration."
        return
    fi

    echo "Please select the primary GPU for Hyprland:"
    select selected_lspci_line in "${menu_options[@]}"; do
        if [[ -n "$selected_lspci_line" ]]; then
            local selected_gpu_path=${lspci_line_to_device_path["$selected_lspci_line"]}

            echo "You selected: $selected_lspci_line"

            # Create an ordered list of devices, with the selected one first.
            local ordered_devices=("$selected_gpu_path")
            for device in "${lspci_line_to_device_path[@]}"; do
                if [[ "$device" != "$selected_gpu_path" ]]; then
                    ordered_devices+=("$device")
                fi
            done

            # Join the device paths with a colon
            local final_device_string
            final_device_string=$(printf "%s:" "${ordered_devices[@]}")
            final_device_string=${final_device_string%:} # Remove trailing colon

            echo "Using device path string: $final_device_string"

            local env_var_line="env = AQ_DRM_DEVICES,$final_device_string"
            local env_conf_file="$HOME/.config/hypr/custom/env.conf"

            mkdir -p "$(dirname "$env_conf_file")"

            if [ -f "$env_conf_file" ]; then
                sed -i '/^env = AQ_DRM_DEVICES/d' "$env_conf_file"
            fi
            
            echo "Adding '$env_var_line' to $env_conf_file"
            echo "$env_var_line" >> "$env_conf_file"
            echo "GPU configuration updated."

            break
        else
            echo "Invalid selection. Please try again."
        fi
    done
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

    for config_app_dir in "$CONFIGS_DIR_REPO"/*; do
        if [ -d "$config_app_dir" ]; then
            config_name=$(basename "$config_app_dir")

            if [ "$MODE" == "save" ]; then
                local system_path="$CONFIGS_DIR_SYSTEM/$config_name"
                local repo_path="$CONFIGS_DIR_REPO/$config_name"
                sync_files "$system_path" "$repo_path" "$config_name"

            elif [ "$MODE" == "load" ]; then
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

    if [ "$MODE" == "load" ]; then
        configure_gpu_device
    fi

    echo "============================================================"
    echo "Configuration sync finished successfully."
    echo "============================================================"
}

#-------------------------------------------------------
# Script Execution
#-------------------------------------------------------
main