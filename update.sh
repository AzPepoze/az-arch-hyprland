#!/bin/bash

#-------------------------------------------------------
# Script Configuration
#-------------------------------------------------------
AUTO_MODE=false
SKIP_CODE_INSIDERS=false

for arg in "$@"; do
    case $arg in
        --auto) 
            AUTO_MODE=true
            shift
            ;; 
        --skip-code-insiders) 
            SKIP_CODE_INSIDERS=true
            shift
            ;; 
        *) 
            # Unknown option
            shift
            ;; 
    esac
done

#-------------------------------------------------------
# Update Functions
#-------------------------------------------------------

repo_dir=$(dirname "$(realpath "$0")")
source "$repo_dir/scripts/install_modules/helpers.sh"
source "$repo_dir/scripts/install_modules/04-apps.sh"
source "$repo_dir/scripts/utils/list_gpu.sh" # Source list_gpu.sh for GPU validation

update_repo() {
    echo
    _log INFO "Updating az-arch-hyprland Repository..."
    echo

    git fetch origin

    LOCAL_COMMIT=$(git rev-parse HEAD)
    REMOTE_COMMIT=$(git rev-parse origin/main)

    if [ "$LOCAL_COMMIT" != "$REMOTE_COMMIT" ]; then
        _log INFO "Local repository is behind origin/main. Updating..."
        git reset --hard origin/main
        _log SUCCESS "Repository updated. Please re-run this script manually if it does not restart automatically."
        _log INFO "Re-running the update script..."
        exec "$0" "$@"
    else
        _log INFO "Repository is already up-to-date."
    fi
}

update_system_packages() {
    echo
    echo "============================================================="
    echo " Updating System & AUR Packages (paru)"
    echo "============================================================="
    if command -v paru &> /dev/null; then
        paru -Syu --noconfirm
    else
        _log WARN "paru command not found. Skipping system package update."
        _log INFO "Please install paru to enable this feature."
    fi
}

update_vscode_insiders() {
    if [ "$SKIP_CODE_INSIDERS" = true ]; then
        _log INFO "Skipping VS Code Insiders update as requested."
        return
    fi

    echo
    echo "============================================================="
    echo " Updating VS Code Insiders (code-insiders-bin)"
    echo "============================================================="
    if ! command -v paru &> /dev/null; then
        _log WARN "paru command not found. Skipping VS Code Insiders update."
        _log INFO "Please install paru to enable this feature."
        return
    fi

    if ! command -v code-insiders &> /dev/null; then
        _log INFO "VS Code Insiders (code-insiders) command not found. Skipping update."
        return
    fi

    # Check if code-insiders-bin is outdated using paru
    if paru -Qqu code-insiders-bin &> /dev/null; then
        _log INFO "VS Code Insiders (code-insiders-bin) is outdated. Updating..."
        paru -S --noconfirm code-insiders-bin
        _log SUCCESS "VS Code Insiders updated."
    else
        _log INFO "VS Code Insiders is already up-to-date."
    fi
}

update_flatpak() {
    echo
    echo "============================================================="
    echo " Updating Flatpak Packages"
    echo "============================================================="
    if command -v flatpak &> /dev/null; then
        flatpak update -y
    else
        _log WARN "flatpak command not found. Skipping Flatpak update."
    fi
}

update_gemini_cli() {
    echo
    echo "============================================================="
    echo " Update Gemini CLI"
    echo "============================================================="

    if ! command -v pnpm &> /dev/null; then
        _log WARN "pnpm command not found. Skipping Gemini CLI update."
        _log INFO "Please install pnpm to enable this feature."
        return
    fi

    if ! command -v gemini &> /dev/null; then
        _log INFO "Gemini CLI not found. Skipping update."
        return
    fi

    local current_version
    current_version=$(gemini -v 2>/dev/null)

    local latest_version
    latest_version=$(npm show @google/gemini-cli version 2>/dev/null)

    if [ -z "$current_version" ]; then
        _log INFO "Gemini CLI not found. Attempting installation."
        pnpm install -g @google/gemini-cli
        _log SUCCESS "Gemini CLI installed."
        return
    fi

    if [ -z "$latest_version" ]; then
        _log WARN "Could not determine latest Gemini CLI version. Skipping update."
        return
    fi

    # Compare versions numerically
    if [[ "$current_version" < "$latest_version" ]]; then
        _log INFO "Gemini CLI (current: $current_version) is not latest (latest: $latest_version). Updating..."
        pnpm install -g @google/gemini-cli
        _log SUCCESS "Gemini CLI updated to $latest_version."
    else
        _log INFO "Gemini CLI is already up-to-date (version: $current_version)."
    fi
}

load_v4l2loopback_module() {
    echo
    echo "============================================================="
    echo " Loading v4l2loopback module"
    echo "============================================================="
    sudo modprobe v4l2loopback
    _log SUCCESS "v4l2loopback module loaded."
}

update_dots_hyprland() {
    echo
    echo "============================================================="
    echo " Updating dots-hyprland"
    echo "============================================================="
    if [ ! -d "$HOME/dots-hyprland" ]; then
        _log WARN "dots-hyprland directory not found. Skipping dots-hyprland update."
        _log INFO "Please install dots-hyprland first if you wish to update it."
        return
    fi

    cd "$HOME/dots-hyprland" && git pull
    _log SUCCESS "dots-hyprland repository updated."

    local update_choice
    if [ "$AUTO_MODE" = true ]; then
        _log INFO "Auto mode enabled. Selecting 'Update (unstable)'."
        update_choice=2
    else
        _log INFO "Please choose the update type:"
        _log INFO "  1) Install (fully update)"
        _log INFO "  2) Update (unstable)"
        read -p "Enter your choice [1-2]: " update_choice
    fi

    case $update_choice in
        1) 
            _log INFO "Running full install..."
            ./install.sh -c -f
            _log SUCCESS "dots-hyprland updated successfully."
            ;; 
        2)
            _log INFO "Running unstable update (automated with expect)..."

            if ! command -v expect &> /dev/null; then
                _log ERROR "Error: 'expect' command not found."
                _log INFO "This automation requires 'expect'. Please install it first."
                _log INFO "On Arch Linux, you can run: sudo pacman -Syu expect"
                cd - >/dev/null
                return 1
            fi

            expect <<'END_OF_EXPECT'
set timeout 120

spawn bash update.sh

expect {
    timeout { 
        puts "\nError: Timeout waiting for the initial (y/N) prompt."
        exit 1
    }
    -re "[(y/N)]:" {
        send "y\r"
    }
}

expect {
    -re "Enter your choice \(1-7\):" {
        send "1\r"
        exp_continue
    }
    eof {
        exit 0
    }
    timeout {
        puts "\nError: Timeout while waiting for a prompt or for the script to finish."
        exit 1
    }
}
END_OF_EXPECT

            _log SUCCESS "dots-hyprland update process finished."
            ;; 
        *) 
            _log WARN "Invalid choice. Skipping dots-hyprland script execution."
            ;; 
    esac
    cd - >/dev/null
}


load_configs() {
    echo
    echo "============================================================="
    echo " Load Configurations"
    echo "============================================================="

    local monitor_config_path="$HOME/.config/hypr/monitors.conf"
    local temp_dir
    temp_dir=$(mktemp -d)
    local backup_monitor_config_path="$temp_dir/monitors.conf"
    local config_script="./cli/load_configs.sh"
    local gpu_conf_file="$HOME/.config/hypr/gpu.conf"
    local skip_gpu_flag=""

    if [ -f "$monitor_config_path" ]; then
        _log INFO "Backing up '$monitor_config_path'..."
        cp "$monitor_config_path" "$backup_monitor_config_path"
    else
        _log WARN "Warning: '$monitor_config_path' not found. Nothing to back up."
    fi

    # Validate existing GPU configuration before loading
    local check_gpu_script="$repo_dir/scripts/utils/check_valid_gpu.sh"
    _log INFO "Validating existing GPU configuration..."
    if bash "$check_gpu_script"; then
        _log SUCCESS "Existing GPU configuration is valid. Skipping GPU selection."
        skip_gpu_flag="--skip-gpu"
    else
        _log WARN "Existing GPU configuration is invalid. GPU selection will be required during config load."
    fi

    if [ -f "$config_script" ]; then
        if [ "$AUTO_MODE" = true ]; then
            bash "$config_script" "$skip_gpu_flag" --skip-cursor
        else
            bash "$config_script"
        fi
    else
        _log WARN "'$config_script' not found. Skipping config load."
    fi

    if [ -f "$backup_monitor_config_path" ]; then
        _log INFO "Restoring '$monitor_config_path'..."
        mkdir -p "$(dirname "$monitor_config_path")"
        cp "$backup_monitor_config_path" "$monitor_config_path"
    fi

    rm -rf "$temp_dir"
    _log SUCCESS "Configuration load process finished."
}

#-------------------------------------------------------
# Script Execution
#-------------------------------------------------------

fastfetch

update_repo

echo
_log INFO "Starting full system update process..."

echo

update_system_packages
update_vscode_insiders
fix_vscode_permissions
update_flatpak
update_gemini_cli
load_v4l2loopback_module
update_dots_hyprland
load_configs
bash ./cli/cleanup.sh

_log SUCCESS "Full system update and cleanup process has finished."
