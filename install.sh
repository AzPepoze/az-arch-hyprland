#!/bin/bash

#-------------------------------------------------------
# Global Variables
#-------------------------------------------------------
repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

#-------------------------------------------------------
# Helper Functions
#-------------------------------------------------------

ask_yes_no() {
     local question="$1"
     local prompt="[y/n]"

     while true; do
          read -p "$question $prompt: " response
          case "$response" in
          [yY][eE][sS] | [yY]) return 0 ;;
          [nN][oO] | [nN]) return 1 ;;
          *) echo "Please answer yes or no." ;;
          esac
     done
}

install_pacman_package() {
     local package="$1"
     local friendly_name="$2"
     echo "Installing $friendly_name..."
     sudo pacman -S --needed "$package" --noconfirm
     echo "$friendly_name installation completed successfully."
}

install_paru_package() {
     local package="$1"
     local friendly_name="$2"
     if ! command -v paru &>/dev/null; then
          echo "Error: paru is not installed. Skipping $friendly_name installation."
          echo "Please install paru first."
          return 1
     fi
     echo "Installing $friendly_name ($package) using paru..."
     paru -S --noconfirm "$package"
     echo "$friendly_name installation completed successfully."
}

install_flatpak_package() {
     local package_id="$1"
     local friendly_name="$2"
     if ! command -v flatpak &>/dev/null; then
          echo "Error: Flatpak is not installed. Skipping $friendly_name installation."
          echo "Please install Flatpak first."
          return 1
     fi
     echo "Installing $friendly_name from Flathub..."
     flatpak install flathub "$package_id" -y
     echo "$friendly_name installation completed."
}

#-------------------------------------------------------
# Group: Core System & Package Management
#-------------------------------------------------------

install_paru() {
     echo "Installing paru (AUR Helper)..."
     if command -v paru &>/dev/null; then
          echo "paru is already installed."
          return 0
     fi

     echo "Installing dependencies for paru (git, base-devel)..."
     sudo pacman -S --needed git base-devel --noconfirm

     local temp_dir
     temp_dir=$(mktemp -d)
     if [ -z "$temp_dir" ]; then
          echo "Error: Could not create temporary directory."
          return 1
     fi

     echo "Cloning paru from AUR into a temporary directory..."
     if ! git clone https://aur.archlinux.org/paru.git "$temp_dir/paru"; then
          echo "Error: Failed to clone paru repository."
          rm -rf "$temp_dir"
          return 1
     fi

     (
          cd "$temp_dir/paru" || exit 1
          echo "Building and installing paru..."
          makepkg -si --noconfirm
     )

     echo "Cleaning up..."
     rm -rf "$temp_dir"
}

install_flatpak() {
     install_pacman_package "flatpak" "Flatpak"
}

install_fuse() {
     install_paru_package "fuse" "FUSE (Filesystem in Userspace)"
}

install_npm() {
     install_pacman_package "npm" "npm"
}

install_pnpm() {
     install_paru_package "pnpm" "pnpm"
}

#-------------------------------------------------------
# Group: Desktop Environment - Hyprland
#-------------------------------------------------------

install_hyde() {
     echo "Checking for and installing necessary dependencies (git, base-devel)..."
     sudo pacman -S --needed git base-devel --noconfirm

     echo "Cloning and running HyDE installer..."
     if [ ! -d "$HOME/HyDE" ]; then
          git clone --depth 1 https://github.com/HyDE-Project/HyDE ~/HyDE
     fi
     (
          cd ~/HyDE/Scripts || {
               echo "Error: Failed to cd into ~/HyDE/Scripts"
               exit 1
          }
          git pull
          ./install.sh
     )
}

install_hyprspace() {
     if ! command -v paru &>/dev/null; then
          echo "Error: paru is not installed. Skipping Hyprspace dependency installation."
          echo "Please install paru first."
          return 1
     fi
     echo "Installing Hyprspace dependencies (cpio, cmake, etc.)..."
     paru -S --noconfirm cpio cmake git meson gcc

     echo "Adding and enabling Hyprspace plugin via hyprpm..."
     hyprpm update
     hyprpm add https://github.com/KZDKM/Hyprspace
     hyprpm enable Hyprspace
     echo "Hyprspace plugin has been enabled."
}

copy_hypr_configs() {
     local config_src_dir="$repo_dir/configs/hypr"
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

#-------------------------------------------------------
# Group: System Utilities
#-------------------------------------------------------

install_inotify_tools() {
     install_pacman_package "inotify-tools" "inotify-tools"
}

install_power_options() {
     install_paru_package "power-options-gtk-git" "Power Options"
}

install_mission_center() {
     install_paru_package "mission-center" "Mission Center"
}

install_rclone() {
     install_paru_package "rclone" "rclone"
}

setup_rclone_gdrive() {
     echo
     echo "Starting rclone configuration for Google Drive..."
     echo "You will be guided through the setup process by rclone."
     echo "When asked, choose 'n' for a new remote."
     echo "Name it 'gdrive' (or a name of your choice)."
     echo "Select the number corresponding to 'drive' (Google Drive)."
     echo "Leave client_id and client_secret blank."
     echo "Choose '1' for full access to all files."
     echo "Leave root_folder_id and service_account_file blank."
     echo "Choose 'n' for Edit advanced config."
     echo "Choose 'y' for Use auto config."
     echo "Follow the browser instructions to authorize rclone."
     echo "Choose 'y' to confirm the new remote."
     echo "Finally, choose 'q' to quit the configuration."
     echo

     mkdir -p ~/GoogleDrive

     rclone config

     echo "rclone configuration Google Drive finished."
}

#-------------------------------------------------------
# Group: Applications
#-------------------------------------------------------

install_vesktop() {
     install_flatpak_package "dev.vencord.Vesktop" "Vesktop"
}

setup_vesktop_rpc() {
     echo "Setting up Vencord/Vesktop Activity Status (for Flatpak)..."
     mkdir -p ~/.config/user-tmpfiles.d

     echo 'L %t/discord-ipc-0 - - - - .flatpak/dev.vencord.Vesktop/xdg-run/discord-ipc-0' >~/.config/user-tmpfiles.d/discord-rpc.conf
     systemctl --user enable --now systemd-tmpfiles-setup.service
     echo "Activity Status setup completed successfully."
}

clone_thai_fonts_css() {
     local source_file="$repo_dir/configs/thai_fonts.css"
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

install_youtube_music() {
     install_paru_package "youtube-music-bin" "YouTube Music"
}

install_steam() {
     install_paru_package "steam" "Steam"
}

install_ms_edge() {
     install_paru_package "microsoft-edge-dev-bin" "Microsoft Edge (Dev)"
}

install_zen_browser() {
     install_flatpak_package "app.zen_browser.zen" "Zen Browser"
}

install_pinta() {
     install_pacman_package "pinta" "Pinta"
}

install_switcheroo() {
     install_paru_package "switcheroo" "Switcheroo"
}

install_bleachbit() {
     install_paru_package "bleachbit" "BleachBit"
}



#-------------------------------------------------------
# Group: Theming & Customization
#-------------------------------------------------------

install_wallpaper_engine() {
     install_paru_package "linux-wallpaperengine-git" "Wallpaper Engine"
}

install_wallpaper_engine_gui_manual() {
     echo "Starting manual installation of Linux Wallpaper Engine GUI..."
     echo "Installing build dependencies (base-devel, curl)..."
     sudo pacman -S --needed base-devel curl --noconfirm

     local build_dir="$HOME/linux-wallpaperengine-gui-build"
     local pkgbuild_url="https://raw.githubusercontent.com/AzPepoze/linux-wallpaperengine-gui/main/installer/PKGBUILD"

     echo "Creating temporary build directory: $build_dir"
     mkdir -p "$build_dir"

     local build_status=1
     (
          cd "$build_dir" || exit 1

          echo "Downloading PKGBUILD file..."
          if ! curl -O "$pkgbuild_url"; then
               echo "Error: Failed to download PKGBUILD from $pkgbuild_url"
               exit 1
          fi

          echo "Building and installing the package with makepkg..."
          makepkg -si --noconfirm

     )
     build_status=$?

     if [ $build_status -ne 0 ]; then
          echo "Error: Build or installation failed with status $build_status."
     else
          echo "Linux Wallpaper Engine GUI installation completed successfully."
     fi

     echo "Cleaning up the build directory..."
     rm -rf "$build_dir"

     if [ $build_status -eq 0 ] && command -v pnpm &>/dev/null; then
          if ask_yes_no "The build may have installed 'pnpm' as a dependency. Do you want to remove it now?"; then
               echo "Removing pnpm..."
               sudo pacman -Rns --noconfirm pnpm
               echo "'pnpm' has been removed."
          fi
     fi
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
     echo
     echo "--- Installation Suite ---"
     echo " 1) Install ALL components and apply configurations"
     echo
     echo "--- Core System & Package Management ---"
     echo " 2) Install paru (AUR Helper)"
     echo " 3) Install the Flatpak package manager"
     echo " 4) Install FUSE (Filesystem in Userspace)"
     echo " 5) Install npm"
     echo " 6) Install pnpm"
     echo
     echo "--- Desktop Environment - Hyprland ---"
     echo " 7) Install HyDE"
     echo " 8) Install the Hyprspace plugin for Hyprland"
     echo " 9) Copy local Hyprland config files to ~/.config/hypr/"
     echo
     echo "--- System Utilities ---"
     echo " 10) Install inotify-tools"
     echo " 11) Install Power Options (power-options-gtk-git)"
     echo " 12) Install Mission Center"
     echo " 13) Install rclone"
     echo " 14) Setup Google Drive with rclone"
     echo
     echo "--- Applications ---"
     echo " 14) Install Vesktop (requires Flatpak)"
     echo " 15) Set up Vencord/Vesktop Activity Status"
     echo " 16) Clone thai_fonts.css for Vesktop"
     echo " 17) Install YouTube Music"
     echo " 18) Install Steam"
     echo " 19) Install Microsoft Edge (Dev)"
     echo " 20) Install Zen Browser (requires Flatpak)"
     echo " 22) Install Pinta"
     echo " 23) Install Switcheroo"
     echo " 24) Install BleachBit"
     echo
     echo "--- Theming & Customization ---"
     echo " 24) Install Wallpaper Engine"
     echo " 25) Install Linux Wallpaper Engine GUI (Manual Build)"
     echo " 26) Install SDDM Astronaut Theme"
     echo "------------------------------------------------------------"
     echo " 27) Exit"
     echo "------------------------------------------------------------"
}

main_menu() {
     while true; do
          show_menu
          read -p "Enter your choice [1-27]: " choice

          echo "------------------------------------------------------------"

          case $choice in
          1)
               echo "Starting full installation process..."
               echo "You will be asked to confirm each step."

               if ask_yes_no "Install paru (AUR Helper)?"; then install_paru; fi
               if ask_yes_no "Install Flatpak?"; then install_flatpak; fi
               if ask_yes_no "Install FUSE?"; then install_fuse; fi
               if ask_yes_no "Install npm?"; then install_npm; fi
               if ask_yes_no "Install pnpm?"; then install_pnpm; fi

               if ask_yes_no "Install HyDE?"; then install_hyde; fi
               if ask_yes_no "Install the Hyprspace plugin for Hyprland?"; then install_hyprspace; fi
               if ask_yes_no "Copy local Hyprland config files?"; then copy_hypr_configs; fi

               if ask_yes_no "Install inotify-tools?"; then install_inotify_tools; fi
               if ask_yes_no "Install Power Options?"; then install_power_options; fi
               if ask_yes_no "Install Mission Center?"; then install_mission_center; fi
               if ask_yes_no "Install rclone?"; then install_rclone; fi
               if ask_yes_no "Setup Google Drive with rclone?"; then setup_rclone_gdrive; fi

               if ask_yes_no "Install Vesktop?"; then install_vesktop; fi
               if ask_yes_no "Set up Vencord/Vesktop Activity Status?"; then setup_vesktop_rpc; fi
               if ask_yes_no "Clone thai_fonts.css for Vesktop?"; then clone_thai_fonts_css; fi
               if ask_yes_no "Install YouTube Music?"; then install_youtube_music; fi
               if ask_yes_no "Install Steam?"; then install_steam; fi
               if ask_yes_no "Install Microsoft Edge (Dev)?"; then install_ms_edge; fi
               if ask_yes_no "Install Zen Browser?"; then install_zen_browser; fi
               if ask_yes_no "Install Pinta?"; then install_pinta; fi
               if ask_yes_no "Install Switcheroo?"; then install_switcheroo; fi
               if ask_yes_no "Install BleachBit?"; then install_bleachbit; fi

               if ask_yes_no "Install Wallpaper Engine?"; then install_wallpaper_engine; fi
               if ask_yes_no "Install Linux Wallpaper Engine GUI (Manual Build)?"; then install_wallpaper_engine_gui_manual; fi
               if ask_yes_no "Install SDDM Astronaut Theme?"; then install_sddm_theme; fi

               echo "Full installation process finished."
               ;;
          2) install_paru ;;
          3) install_flatpak ;;
          4) install_fuse ;;
          5) install_npm ;;
          6) install_pnpm ;;
          7) install_hyde ;;
          8) install_hyprspace ;;
          9) copy_hypr_configs ;;
          10) install_inotify_tools ;;
          11) install_power_options ;;
          12) install_mission_center ;;
          13) install_rclone ;;
          14) setup_rclone_gdrive ;;
          15) install_vesktop ;;
          16) setup_vesktop_rpc ;;
          17) clone_thai_fonts_css ;;
          18) install_youtube_music ;;
          19) install_steam ;;
          20) install_ms_edge ;;
          21) install_zen_browser ;;
          22) install_pinta ;;
          23) install_switcheroo ;;
          24) install_bleachbit ;;
          25) install_wallpaper_engine ;;
          26) install_wallpaper_engine_gui_manual ;;
          27) install_sddm_theme ;;
          28)
               echo "Exiting script. Goodbye!"
               break
               ;;
          *)
               echo "Invalid option '$choice'. Please try again."
               ;;
          esac

          if [[ "$choice" != "27" ]]; then
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
