#!/bin/bash

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
