#!/bin/bash

#-------------------------------------------------------
# Group: Theming & Customization
#-------------------------------------------------------

install_wallpaper_engine() {
     install_paru_package "linux-wallpaperengine-git" "Wallpaper Engine"
}

install_wallpaper_engine_gui_manual() {
     _log INFO "Starting manual installation of Linux Wallpaper Engine GUI..."
     _log INFO "Installing build dependencies (base-devel, curl)..."
     sudo pacman -S --needed base-devel curl --noconfirm

     local build_dir="$HOME/linux-wallpaperengine-gui-build"
     local pkgbuild_url="https://raw.githubusercontent.com/AzPepoze/linux-wallpaperengine-gui/main/installer/PKGBUILD"

     _log INFO "Creating temporary build directory: $build_dir"
     mkdir -p "$build_dir"

     local build_status=1
     (
          cd "$build_dir" || exit 1

          _log INFO "Downloading PKGBUILD file..."
          if ! curl -O "$pkgbuild_url"; then
               _log ERROR "Failed to download PKGBUild from $pkgbuild_url"
               exit 1
          fi

          _log INFO "Building and installing the package with makepkg..."
          makepkg -si --noconfirm

     )
     build_status=$?

     if [ $build_status -ne 0 ]; then
          _log ERROR "Build or installation failed with status $build_status."
     else
          _log SUCCESS "Linux Wallpaper Engine GUI installation completed successfully."
     fi

     _log INFO "Cleaning up the build directory..."
     rm -rf "$build_dir"

     if [ $build_status -eq 0 ] && command -v pnpm &>/dev/null; then
          if ask_yes_no "The build may have installed 'pnpm' as a dependency. Do you want to remove it now?"; then
               _log INFO "Removing pnpm..."
               sudo pacman -Rns --noconfirm pnpm
               _log INFO "'pnpm' has been removed."
          fi
     fi
}

install_sddm_theme() {
     _log INFO "Installing SDDM Astronaut Theme..."
     sh -c "$(curl -fsSL https://raw.githubusercontent.com/keyitdev/sddm-astronaut-theme/master/setup.sh)"
     _log INFO "SDDM Astronaut Theme installation attempted."
}

#-------------------------------------------------------
# Catppuccin Fish Theme Installation
#-------------------------------------------------------
install_catppuccin_fish_theme() {
    _log INFO "Installing Catppuccin theme for fish shell..."
    fisher install catppuccin/fish
    fish_config theme save "Catppuccin Mocha"
    _log SUCCESS "Catppuccin Mocha theme installed and set for fish shell."
}