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
    hyprpm update
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

install_caprine() {
    if ! command -v flatpak &> /dev/null; then
        echo "Error: Flatpak is not installed. Skipping Caprine installation."
        echo "Please install Flatpak first."
        return 1
    fi
    echo "Installing Caprine from Flathub..."
    flatpak install flathub com.sindresorhus.Caprine -y
    echo "Caprine installation completed."
}

override_caprine() {
    echo "Applying Flatpak override for Caprine..."
    flatpak override --user --socket=wayland com.sindresorhus.Caprine
    echo "Caprine override completed."
}

clone_thai_fonts_css() {
    local script_dir
    script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
    local source_file="$script_dir/../configs/thai_fonts.css"
    local dest_file="$HOME/.var/app/dev.vencord.Vesktop/config/vesktop/settings/quickCss.css"
    local dest_dir

    dest_dir=$(dirname "$dest_file")

    echo "Cloning Thai fonts CSS for Vesktop..."

    if [ ! -f "$source_file" ]; then
        echo "Error: Source file not found at $source_file"
        return 1
    fi

    echo "Ensuring destination directory exists: $dest_dir"
    mkdir -p "$dest_dir"

    cp -v "$source_file" "$dest_file"
    echo "Successfully cloned thai_fonts.css to the Vesktop directory."
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
    echo " 1) Install ALL components and apply configurations"
    echo " 2) Install HyDE"
    echo " 3) Install Power Options (power-options-gtk-git)"
    echo " 4) Install the Flatpak package manager"
    echo " 5) Install Vesktop (requires Flatpak)"
    echo " 6) Set up Vencord/Vesktop Activity Status"
    echo " 7) Install Mission Center"
    echo " 8) Install FUSE (Filesystem in Userspace)"
    echo " 9) Install the Hyprspace plugin for Hyprland"
    echo " 10) Install YouTube Music"
    echo " 11) Install Wallpaper Engine"
    echo " 12) Install Steam"
    echo " 13) Copy local Hyprland config files to ~/.config/hypr/"
    echo " 14) Install SDDM Astronaut Theme"
    echo " 15) Install Caprine"
    echo " 16) Add Flatpak override for Caprine"
    echo " 17) Clone thai_fonts.css for Vesktop"
    echo "------------------------------------------------------------"
    echo " 18) Exit"
    echo "------------------------------------------------------------"
}

main_menu() {
    while true; do
        show_menu
        read -p "Enter your choice [1-18]: " choice
        
        echo "------------------------------------------------------------"

        case $choice in
            1)
                echo "Starting full installation process..."
                echo "You will be asked to confirm each step."

                if ask_yes_no "Install HyDE?"; then install_hyde; fi
                if ask_yes_no "Install Power Options?"; then install_power_options; fi
                if ask_yes_no "Install Flatpak?"; then install_flatpak; fi
                if ask_yes_no "Install Vesktop?"; then install_vesktop; fi
                if ask_yes_no "Set up Vencord/Vesktop Activity Status?"; then setup_vesktop_rpc; fi
                if ask_yes_no "Install Mission Center?"; then install_mission_center; fi
                if ask_yes_no "Install FUSE?"; then install_fuse; fi
                if ask_yes_no "Install the Hyprspace plugin for Hyprland?"; then install_hyprspace; fi
                if ask_yes_no "Install YouTube Music?"; then install_youtube_music; fi
                if ask_yes_no "Install Wallpaper Engine?"; then install_wallpaper_engine; fi
                if ask_yes_no "Install Steam?"; then install_steam; fi
                if ask_yes_no "Copy local Hyprland config files?"; then copy_hypr_configs; fi
                if ask_yes_no "Install SDDM Astronaut Theme?"; then install_sddm_theme; fi
                if ask_yes_no "Install Caprine?"; then install_caprine; fi
                if ask_yes_no "Add Flatpak override for Caprine?"; then override_caprine; fi
                if ask_yes_no "Clone thai_fonts.css for Vesktop?"; then clone_thai_fonts_css; fi

                echo "Full installation process finished."
                ;;
            2) install_hyde ;;
            3) install_power_options ;;
            4) install_flatpak ;;
            5) install_vesktop ;;
            6) setup_vesktop_rpc ;;
            7) install_mission_center ;;
            8) install_fuse ;;
            9) install_hyprspace ;;
            10) install_youtube_music ;;
            11) install_wallpaper_engine ;;
            12) install_steam ;;
            13) copy_hypr_configs ;;
            14) install_sddm_theme ;;
            15) install_caprine ;;
            16) override_caprine ;;
            17) clone_thai_fonts_css ;;
            18)
                echo "Exiting script. Goodbye!"
                break
                ;;
            *)
                echo "Invalid option '$choice'. Please try again."
                ;;
        esac
        
        if [[ "$choice" != "18" ]]; then
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
