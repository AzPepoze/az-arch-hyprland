#!/bin/bash

ask_yes_no() {
    while true; do
        read -p "$1 [y/N]: " response
        case "$response" in
            [yY][eE][sS]|[yY]) 
                return 0 
                ;;
            [nN][oO]|[nN]|"")
                return 1 
                ;;
            *)
                echo "Please answer yes or no."
                ;;
        esac
    done
}

echo "------------------------------------------------------------"

#
#------------------------------------------------------
# Install HyDE
#-------------------------------------------------------
#
if ask_yes_no "Do you want to install HyDE?"; then
    echo "Checking for and installing necessary dependencies (git, base-devel)..."
    sudo pacman -S --needed git base-devel --noconfirm
    
    git clone --depth 1 https://github.com/HyDE-Project/HyDE ~/HyDE
    cd ~/HyDE/Scripts
    ./install.sh
else
    echo "Skipping HyDE installation."
fi

echo "------------------------------------------------------------"

#
#------------------------------------------------------
# Install Power Options
#-------------------------------------------------------
#
if ask_yes_no "Do you want to install Power Options (power-options-gtk-git)?"; then
    echo "Installing Power Options using yay..."
    yay -S --noconfirm power-options-gtk-git
    echo "Power Options installation completed successfully."
else
    echo "Skipping Power Options installation."
fi

echo "------------------------------------------------------------"

#
#------------------------------------------------------
# Install Flatpak
#-------------------------------------------------------
#
if ask_yes_no "Do you want to install the Flatpak package manager?"; then
    echo "Installing Flatpak..."
    sudo pacman -S --needed flatpak --noconfirm
    echo "Flatpak installation completed."
else
    echo "Skipping Flatpak installation."
fi

echo "------------------------------------------------------------"

#
#------------------------------------------------------
# Install Vesktop (via Flatpak)
#-------------------------------------------------------
#
if ask_yes_no "Do you want to install Vesktop (requires Flatpak)?"; then
    if ! command -v flatpak &> /dev/null; then
        echo "Error: Flatpak is not installed. Skipping Vesktop installation."
    else
        echo "Installing Vesktop from Flathub..."
        flatpak install flathub dev.vencord.Vesktop -y
        echo "Vesktop installation completed."
    fi
else
    echo "Skipping Vesktop installation."
fi

echo "------------------------------------------------------------"

#
#------------------------------------------------------
# Setup Vencord/Vesktop Flatpak Rich Presence
#-------------------------------------------------------
#
if ask_yes_no "Do you want to set up Vencord/Vesktop Activity Status (for Flatpak)?"; then
    echo "Setting up Activity Status..."
    mkdir -p ~/.config/user-tmpfiles.d
    echo 'L %t/discord-ipc-0 - - - - .flatpak/dev.vencord.Vesktop/xdg-run/discord-ipc-0' > ~/.config/user-tmpfiles.d/discord-rpc.conf
    systemctl --user enable --now systemd-tmpfiles-setup.service
    echo "Activity Status setup completed successfully."
else
    echo "Skipping Activity Status setup."
fi

echo "------------------------------------------------------------"

#
#------------------------------------------------------
# Install Mission Center
#-------------------------------------------------------
#
if ask_yes_no "Do you want to install Mission Center?"; then
    echo "Installing Mission Center..."
    yay -S --noconfirm mission-center
    echo "Mission Center installation completed."
else
    echo "Skipping Mission Center installation."
fi

echo "------------------------------------------------------------"

#
#------------------------------------------------------
# Install FUSE
#-------------------------------------------------------
#
if ask_yes_no "Do you want to install FUSE (Filesystem in Userspace)?"; then
    echo "Installing FUSE..."
    yay -S --noconfirm fuse
    echo "FUSE installation completed."
else
    echo "Skipping FUSE installation."
fi

echo "------------------------------------------------------------"

#
#------------------------------------------------------
# Install Hyprspace Plugin for Hyprland
#-------------------------------------------------------
#
if ask_yes_no "Do you want to install the Hyprspace plugin for Hyprland?"; then
    echo "Installing Hyprspace dependencies (cpio, cmake, etc.)..."
    yay -S --noconfirm cpio cmake git meson gcc
    
    echo "Adding and enabling Hyprspace plugin via hyprpm..."
    hyprpm add https://github.com/KZDKM/Hyprspace
    hyprpm enable Hyprspace
    echo "Hyprspace plugin has been enabled."
else
    echo "Skipping Hyprspace plugin installation."
fi

echo "------------------------------------------------------------"

#
#------------------------------------------------------
# Copy Hyprland Configuration Files
#-------------------------------------------------------
#
if ask_yes_no "Do you want to copy local Hyprland config files (.conf) to ~/.config/hypr/?"; then
    SCRIPT_DIR=$(dirname "$0")
    CONFIG_DEST_DIR="$HOME/.config/hypr"
    
    echo "Ensuring destination directory exists: $CONFIG_DEST_DIR"
    mkdir -p "$CONFIG_DEST_DIR"
    
    echo "Copying .conf files from $SCRIPT_DIR to $CONFIG_DEST_DIR..."
    cp "$SCRIPT_DIR"/*.conf "$CONFIG_DEST_DIR/"
    
    echo "Configuration files copied successfully."
else
    echo "Skipping Hyprland config file copy."
fi

echo "------------------------------------------------------------"

echo "The script has finished."