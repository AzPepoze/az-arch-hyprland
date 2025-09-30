#!/bin/bash

#-------------------------------------------------------
# Script Configuration
#-------------------------------------------------------
AUTO_MODE=false
SKIP_CODE_INSIDERS=false
LOAD_CONFIGS_ARGS=()

for arg in "$@"; do
    case $arg in
        --auto) 
            AUTO_MODE=true
            ;; 
        --skip-code-insiders) 
            SKIP_CODE_INSIDERS=true
            ;; 
        *) 
            LOAD_CONFIGS_ARGS+=("$arg")
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

    if ! command -v npm &> /dev/null; then
        _log WARN "npm command not found. Skipping Gemini CLI update."
        _log INFO "Please install npm to enable this feature."
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

    if [ -z "$latest_version" ]; then
        _log WARN "Could not determine latest Gemini CLI version. Skipping update."
        return
    fi

    if [[ "$current_version" < "$latest_version" ]]; then
        _log INFO "Gemini CLI (current: $current_version) is not latest (latest: $latest_version). Updating..."
        sudo npm install -g @google/gemini-cli
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




load_configs() {
    echo
    echo "============================================================="
    echo " Load Configurations"
    echo "============================================================="

    local config_script="./cli/load_configs.sh"

    if [ -f "$config_script" ]; then
        # Pass filtered arguments to load_configs.sh
        bash "$config_script" "${LOAD_CONFIGS_ARGS[@]}"
    else
        _log WARN "'$config_script' not found. Skipping config load."
    fi
    _log SUCCESS "Configuration load process finished."
}

#-------------------------------------------------------
# Script Execution
#-------------------------------------------------------

# fastfetch

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
load_configs
bash ./cli/cleanup.sh

_log SUCCESS "Full system update and cleanup process has finished."
