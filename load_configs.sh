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
# Configuration
#-------------------------------------------------------
REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
CONFIGS_DIR_REPO="$REPO_DIR/configs"
CONFIGS_DIR_SYSTEM="$HOME/.config"

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

    # Removed --delete flag to prevent deleting files in the destination
    rsync -av "$source_dir/" "$dest_dir/"
    echo "---------------------------"
}

configure_gpu_device() {
    echo "Detecting available GPUs..." >&2

    if ! command -v lspci &>/dev/null; then
        _log ERROR "lspci command not found. Please install pciutils."
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
            _log ERROR "Invalid selection. Please try again."
        fi
    done
}

update_gpu_conf() {
    local gpu_device=$1

    if [ -z "$gpu_device" ]; then
        _log WARN "No GPU device provided. Skipping Hyprland GPU configuration."
        return
    fi

    local env_var_line="env = WLR_DRM_DEVICES,$gpu_device"
    local gpu_conf_file="$CONFIGS_DIR_SYSTEM/hypr/gpu.conf"

    mkdir -p "$(dirname "$gpu_conf_file")"

    echo "# GPU settings managed by config-loader" > "$gpu_conf_file"
    _log INFO "Adding '$env_var_line' to $gpu_conf_file"
    echo "$env_var_line" >> "$gpu_conf_file"
}

update_cursor_conf() {
    local theme=$1
    local size=$2

    if [ -z "$theme" ]; then
        _log WARN "No cursor theme provided. Skipping cursor.conf generation."
        return
    fi
    
    _log INFO "Updating cursor configuration..."

    local cursor_conf_file="$CONFIGS_DIR_SYSTEM/hypr/cursor.conf"
    mkdir -p "$(dirname "$cursor_conf_file")"

    # Write the configuration to the file
    cat > "$cursor_conf_file" <<- EOL
# Cursor settings managed by config-loader
env = XCURSOR_THEME,$theme
exec-once = hyprctl setcursor $theme $size
EOL

    _log SUCCESS "Successfully generated '$cursor_conf_file' for theme '$theme' with size $size."
}

configure_cursor_theme() {
    # All status messages are redirected to stderr (>&2)
    # to avoid being captured by command substitution.
    echo "Starting Cursor Theme Installation..." >&2

    local built_themes_dir="$REPO_DIR/dist/cursors"
    local user_icon_dir="$HOME/.local/share/icons"

    if [ ! -d "$built_themes_dir" ] || [ -z "$(ls -A "$built_themes_dir")" ]; then
        _log ERROR "Built cursor themes not found in '$built_themes_dir'."
        echo "Please run the './build_cursors.sh' script from the project root first." >&2
        return 1
    fi

    mapfile -t themes < <(find "$built_themes_dir" -maxdepth 1 -mindepth 1 -type d -exec basename {} \;)
    if [ ${#themes[@]} -eq 0 ]; then
        _log ERROR "No themes found in '$built_themes_dir'."
        return 1
    fi

    themes+=("Exit")

    echo "Select the cursor theme to install:" >&2
    select theme_name in "${themes[@]}"; do
        case "$theme_name" in
            "Exit")
                echo "Exiting without installation." >&2
                return 0
                ;;
            *)
                if [[ " ${themes[*]} " =~ " ${theme_name} " ]]; then
                    echo "Installing theme: $theme_name" >&2

                    mkdir -p "$user_icon_dir"
                    echo "Ensured icon directory exists at '$user_icon_dir'" >&2

                    cp -r "$built_themes_dir/$theme_name" "$user_icon_dir/"
                    # THIS IS THE FIX: Redirect the _log output to stderr
                    _log SUCCESS "Copied '$theme_name' to '$user_icon_dir'" >&2
                    
                    # This is the only echo to stdout, serving as the return value.
                    echo "$theme_name"
                    break
                else
                    _log ERROR "Invalid option '$REPLY'. Please try again."
                fi
                ;;
        esac
    done
}

patch_quickshell_background() {
    echo "--- Patching QuickShell Background ---"
    local qml_file="$HOME/.config/quickshell/ii/modules/background/Background.qml"

    if [ -f "$qml_file" ]; then
        _log INFO "Found QuickShell Background.qml at '$qml_file'. Patching..."
        sed -i 's/visible: !bgRoot.wallpaperIsVideo/visible: false \/\/ !bgRoot.wallpaperIsVideo/g' "$qml_file"
        _log SUCCESS "Successfully patched QuickShell Background.qml."
    else
        _log WARN "QuickShell Background.qml not found at '$qml_file'. Skipping patch."
    fi
    echo "------------------------------------"
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
    local selected_gpu_device=""
    if [ "$skip_gpu" = false ]; then
        selected_gpu_device=$(configure_gpu_device)
    else
        _log INFO "Skipping GPU configuration due to --skip-gpu flag."
    fi

    # Cursor Theme Configuration
    local selected_cursor_theme=""
    if [ "$skip_cursor" = false ]; then
        selected_cursor_theme=$(configure_cursor_theme)
    else
         _log INFO "Skipping cursor configuration due to --skip-cursor flag."
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

    # Update device-specific config files
    if [ -n "$selected_gpu_device" ]; then
        update_gpu_conf "$selected_gpu_device"
    fi

    if [ -n "$selected_cursor_theme" ]; then
        update_cursor_conf "$selected_cursor_theme" "24" # Default cursor size is 24
    fi
    
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