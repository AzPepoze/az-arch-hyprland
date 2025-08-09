#!/bin/bash

#-------------------------------------------------------
# Script Configuration
#-------------------------------------------------------
AUTO_MODE=false
if [[ "$1" == "--auto" ]]; then
    AUTO_MODE=true
fi

#-------------------------------------------------------
# Update Functions
#-------------------------------------------------------

update_repo() {
    echo
    echo "Updating az-arch-hyprland Repository..."
    echo

    git fetch origin

    LOCAL_COMMIT=$(git rev-parse HEAD)
    REMOTE_COMMIT=$(git rev-parse origin/main)

    if [ "$LOCAL_COMMIT" != "$REMOTE_COMMIT" ]; then
        echo "Local repository is behind origin/main. Updating..."
        git reset --hard origin/main
        echo "Repository updated. Please re-run this script manually if it does not restart automatically."
        echo "Re-running the update script..."
        exec "$0" "$@"
    else
        echo "Repository is already up-to-date."
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
        echo "paru command not found. Skipping system package update."
        echo "Please install paru to enable this feature."
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
        echo "flatpak command not found. Skipping Flatpak update."
    fi
}

update_gemini_cli() {
    echo
    echo "============================================================="
    echo " Update Gemini CLI"
    echo "============================================================="
    if command -v gemini &> /dev/null; then
        sudo npm install -g @google/gemini-cli
    else
        echo "Gemini CLI not found. Skipping update."
    fi
}

load_v4l2loopback_module() {
    echo
    echo "============================================================="
    echo " Loading v4l2loopback module"
    echo "============================================================="
    sudo modprobe v4l2loopback
    echo "v4l2loopback module loaded."
}

update_dots_hyprland() {
    echo
    echo "============================================================="
    echo " Updating dots-hyprland"
    echo "============================================================="
    if [ ! -d "$HOME/dots-hyprland" ]; then
        echo "dots-hyprland directory not found. Skipping dots-hyprland update."
        echo "Please install dots-hyprland first if you wish to update it."
        return
    fi

    cd "$HOME/dots-hyprland" && git pull
    echo "dots-hyprland repository updated."

    local update_choice
    if [ "$AUTO_MODE" = true ]; then
        echo "Auto mode enabled. Selecting 'Update (unstable)'."
        update_choice=2
    else
        echo "Please choose the update type:"
        echo "  1) Install (fully update)"
        echo "  2) Update (unstable)"
        read -p "Enter your choice [1-2]: " update_choice
    fi

    case $update_choice in
        1)
            echo "Running full install..."
            ./install.sh -c -f
            echo "dots-hyprland updated successfully."
            ;;
        2)
            echo "Running unstable update (automated with expect)..."

            if ! command -v expect &> /dev/null; then
                echo "Error: 'expect' command not found."
                echo "This automation requires 'expect'. Please install it first."
                echo "On Arch Linux, you can run: sudo pacman -Syu expect"
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
    -re "\[(y/N)\]:" {
        send "y\r"
    }
}

expect {
    -re "Enter your choice \\(1-7\\):" {
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

            echo "dots-hyprland update process finished."
            ;;
        *)
            echo "Invalid choice. Skipping dots-hyprland script execution."
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
    local config_script="./load_configs.sh"

    if [ -f "$monitor_config_path" ]; then
        echo "Backing up '$monitor_config_path'..."
        cp "$monitor_config_path" "$backup_monitor_config_path"
    else
        echo "Warning: '$monitor_config_path' not found. Nothing to back up."
    fi

    if [ -f "$config_script" ]; then
        if [ "$AUTO_MODE" = true ]; then
            bash ./load_configs.sh --skip-gpu --skip-cursor
        else
            bash ./load_configs.sh
        fi
    else
        echo "'$config_script' not found. Skipping config load."
    fi

    if [ -f "$backup_monitor_config_path" ]; then
        echo "Restoring '$monitor_config_path'..."
        mkdir -p "$(dirname "$monitor_config_path")"
        cp "$backup_monitor_config_path" "$monitor_config_path"
    fi

    rm -rf "$temp_dir"
    echo "Configuration load process finished."
}

#-------------------------------------------------------
# Script Execution
#-------------------------------------------------------

fastfetch

update_repo

echo
echo "Starting full system update process..."
echo

update_system_packages
update_flatpak
update_gemini_cli
load_v4l2loopback_module
update_dots_hyprland
load_configs
bash ./cleanup.sh

echo
echo "Full system update and cleanup process has finished."
