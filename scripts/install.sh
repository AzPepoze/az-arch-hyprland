#!/bin/bash

#-------------------------------------------------------
# Helper Functions
#-------------------------------------------------------

ask_yes_no() {
    local question="$1"
    local prompt="[y/n]"

    while true; do
        read -p "$question $prompt: " response
        case "$response" in
            [yY][eE][sS]|[yY]) return 0 ;;
            [nN][oO]|[nN]) return 1 ;;
            *) echo "Please answer yes or no." ;;
        esac
    done
}

#-------------------------------------------------------
# Installation Tasks
#-------------------------------------------------------

install_hyde() {
    echo "Checking for and installing necessary dependencies (git, base-devel)..."
    sudo pacman -S --needed git base-devel --noconfirm
    
    echo "Cloning and running HyDE installer..."
    git clone --depth 1 https://github.com/HyDE-Project/HyDE ~/HyDE
    cd ~/HyDE/Scripts
    git pull
    ./install.sh
    cd - &> /dev/null
}

install_power_options() {
    echo "Installing Power Options (power-options-gtk-git) using yay..."
    yay -S --noconfirm power-options-gtk-git
    echo "Power Options installation completed successfully."
}

install_flatpak() {
    echo "Installing Flatpak..."
    sudo pacman -S --needed flatpak --noconfirm
    echo "Flatpak installation completed."
}

install_vesktop() {
    if ! command -v flatpak &> /dev/null; then
        echo "Error: Flatpak is not installed. Skipping Vesktop installation."
        echo "Please install Flatpak first."
        return 1
    fi
    echo "Installing Vesktop from Flathub..."
    flatpak install flathub dev.vencord.Vesktop -y
    echo "Vesktop installation completed."
}

setup_vesktop_rpc() {
    echo "Setting up Vencord/Vesktop Activity Status (for Flatpak)..."
    mkdir -p ~/.config/user-tmpfiles.d
    echo 'L %t/discord-ipc-0 - - - - .flatpak/dev.vencord.Vesktop/xdg-run/discord-ipc-0' > ~/.config/user-tmpfiles.d/discord-rpc.conf
    systemctl --user enable --now systemd-tmpfiles-setup.service
    echo "Activity Status setup completed successfully."
}

install_mission_center() {
    echo "Installing Mission Center..."
    yay -S --noconfirm mission-center
    echo "Mission Center installation completed."
}

install_fuse() {
    echo "Installing FUSE (Filesystem in Userspace)..."
    yay -S --noconfirm fuse
    echo "FUSE installation completed."
}

install_hyprspace() {
    echo "Installing Hyprspace dependencies (cpio, cmake, etc.)..."
    yay -S --noconfirm cpio cmake git meson gcc
    
    echo "Adding and enabling Hyprspace plugin via hyprpm..."
    hyprpm add https://github.com/KZDKM/Hyprspace
    hyprpm enable Hyprspace
    echo "Hyprspace plugin has been enabled."
}

copy_hypr_configs() {
    local script_dir
    script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
    local config_src_dir="$script_dir/../configs/hypr"
    local config_dest_dir="$HOME/.config/hypr"

    if [ -d "$config_src_dir" ]; then
        echo "Ensuring destination directory exists: $config_dest_dir"
        mkdir -p "$config_dest_dir"

        echo "Copying .conf files from $config_src_dir to $config_dest_dir..."
        cp -v "$config_src_dir"/*.conf "$config_dest_dir/"
        echo "Configuration files copied successfully."
    else
        echo "Error: Source directory '$config_src_dir' not found. Skipping config file copy."
    fi
}

install_youtube_music() {
    echo "Installing YouTube Music (youtube-music-bin) using yay..."
    yay -S --noconfirm youtube-music-bin
    echo "YouTube Music installation completed successfully."
}

install_wallpaper_engine() {
    echo "Installing Wallpaper Engine (linux-wallpaperengine-git) using yay..."
    yay -S --noconfirm linux-wallpaperengine-git
    echo "Wallpaper Engine installation completed successfully."
}

install_steam() {
    echo "Installing Steam..."
    yay -S --noconfirm steam
    echo "Steam installation completed successfully."
}

install_sddm_theme() {
    echo "Installing SDDM Astronaut Theme..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/keyitdev/sddm-astronaut-theme/master/setup.sh)"
    echo "SDDM Astronaut Theme installation attempted."
}

#-------------------------------------------------------
# Main Logic
#-------------------------------------------------------

show_menu() {
    clear
    echo "------------------------------------------------------------"
    echo " AzP Arch Setup Script - Main Menu"
    echo "------------------------------------------------------------"
    echo "Please select an option:"
    echo " 1) Install HyDE"
    echo " 2) Install Power Options (power-options-gtk-git)"
    echo " 3) Install the Flatpak package manager"
    echo " 4) Install Vesktop (requires Flatpak)"
    echo " 5) Set up Vencord/Vesktop Activity Status"
    echo " 6) Install Mission Center"
    echo " 7) Install FUSE (Filesystem in Userspace)"
    echo " 8) Install the Hyprspace plugin for Hyprland"
    echo " 9) Install YouTube Music"
    echo " 10) Install Wallpaper Engine"
    echo " 11) Install Steam"
    echo " 12) Copy local Hyprland config files to ~/.config/hypr/"
    echo " 13) Install SDDM Astronaut Theme"
    echo "------------------------------------------------------------"
    echo " 14) Install ALL components and apply configurations"
    echo " 15) Exit"
    echo "------------------------------------------------------------"
}

main_menu() {
    while true; do
        show_menu
        read -p "Enter your choice [1-15]: " choice
        
        echo "------------------------------------------------------------"

        case $choice in
            1) install_hyde ;;
            2) install_power_options ;;
            3) install_flatpak ;;
            4) install_vesktop ;;
            5) setup_vesktop_rpc ;;
            6) install_mission_center ;;
            7) install_fuse ;;
            8) install_hyprspace ;;
            9) install_youtube_music ;;
            10) install_wallpaper_engine ;;
            11) install_steam ;;
            12) copy_hypr_configs ;;
            13) install_sddm_theme ;;
            14)
                echo "Starting full installation of all components..."
                install_hyde
                install_power_options
                install_flatpak
                install_vesktop
                setup_vesktop_rpc
                install_mission_center
                install_fuse
                install_hyprspace
                install_youtube_music
                install_wallpaper_engine
                install_steam
                copy_hypr_configs
                install_sddm_theme
                echo "Full installation complete."
                ;;
            15)
                echo "Exiting script. Goodbye!"
                break
                ;;
            *)
                echo "Invalid option '$choice'. Please try again."
                ;;
        esac
        
        if [[ "$choice" != "15" ]]; then
            echo "------------------------------------------------------------"
            read -p "Press Enter to return to the menu..."
        fi
    done
}

echo "------------------------------------------------------------"
echo "This script will guide you through the installation of"
echo "various packages and configurations for your system."
echo "------------------------------------------------------------"

main_menu

echo "------------------------------------------------------------"
echo "The script has finished."