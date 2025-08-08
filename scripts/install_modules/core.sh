#!/bin/bash

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
          _log ERROR "Could not create temporary directory."
          return 1
     fi

     echo "Cloning paru from AUR into a temporary directory..."
     if ! git clone https://aur.archlinux.org/paru.git "$temp_dir/paru"; then
          _log ERROR "Failed to clone paru repository."
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
     echo "Checking pnpm setup..."
     local fish_config="$HOME/.config/fish/config.fish"

     if [ -f "$fish_config" ] && grep -q "pnpm" "$fish_config"; then
          _log INFO "pnpm configuration already exists in $fish_config, skipping setup."
     elif command -v pnpm &>/dev/null; then
          _log INFO "Running pnpm setup..."
          pnpm setup
          _log SUCCESS "pnpm setup completed."
     else
          _log WARN "pnpm command not found, skipping pnpm setup."
     fi
}

install_linux_headers() {
    install_pacman_package "linux-headers" "Linux Headers"
}