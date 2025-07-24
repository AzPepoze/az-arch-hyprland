#!/bin/bash

#-------------------------------------------------------
# Group: Core System & Package Management
#-------------------------------------------------------

install_paru() {
     _log INFO "Installing paru (AUR Helper)..."
     if command -v paru &>/dev/null; then
          _log INFO "paru is already installed."
          return 0
     fi

     _log INFO "Installing dependencies for paru (git, base-devel)..."
     sudo pacman -S --needed git base-devel --noconfirm

     local temp_dir
     temp_dir=$(mktemp -d)
     if [ -z "$temp_dir" ]; then
          _log ERROR "Could not create temporary directory."
          return 1
     fi

     _log INFO "Cloning paru from AUR into a temporary directory..."
     if ! git clone https://aur.archlinux.org/paru.git "$temp_dir/paru"; then
          _log ERROR "Failed to clone paru repository."
          rm -rf "$temp_dir"
          return 1
     fi

     (
          cd "$temp_dir/paru" || exit 1
          _log INFO "Building and installing paru..."
          makepkg -si --noconfirm
     )

     _log INFO "Cleaning up..."
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
     _log INFO "Running pnpm setup..."
     if command -v pnpm &>/dev/null; then
          pnpm setup
          _log SUCCESS "pnpm setup completed."
     else
          _log WARN "pnpm command not found, skipping pnpm setup."
     fi
}

install_linux_headers() {
    install_pacman_package "linux-headers" "Linux Headers"
}