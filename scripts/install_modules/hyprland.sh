#!/bin/bash

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

install_quickshell() {
     install_paru_package "quickshell-git" "Quickshell"
}

copy_quickshell_configs() {
     local config_src_dir="$repo_dir/configs/quickshell/default"
     local config_dest_dir="$HOME/.config/quickshell/default"

     if [ -d "$config_src_dir" ]; then
          echo "Ensuring destination directory exists: $config_dest_dir"
          mkdir -p "$config_dest_dir"

          echo "Copying files from $config_src_dir to $config_dest_dir..."
          cp -v "$config_src_dir"/* "$config_dest_dir/"
          echo "Configuration files copied successfully."
     else
          echo "Error: Source directory '$config_src_dir' not found. Skipping config file copy."
     fi
}
