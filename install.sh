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
    
    if git clone --depth 1 https://github.com/HyDE-Project/HyDE ~/HyDE; then
        cd ~/HyDE/Scripts || exit
        ./install.sh
        echo "HyDE installation completed successfully."
    else
        echo "An error occurred while cloning the HyDE repository."
    fi
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
# Install Flatpak and Vesktop
#-------------------------------------------------------
#
if ask_yes_no "Do you want to install Flatpak and Vesktop?"; then
    echo "Installing Flatpak package manager..."
    sudo pacman -S --needed flatpak --noconfirm
    echo "Installing Vesktop from Flathub..."
    flatpak install flathub dev.vencord.Vesktop -y
    echo "Vesktop installation completed."
else
    echo "Skipping Flatpak and Vesktop installation."
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

echo "The script has finished."