#!/bin/bash

#----------------------------------------------------------------------
# Universal System Updater
#
# This script streamlines the update process for the entire system,
# including the configuration repository, official packages, AUR
# packages, and Flatpak applications.
#----------------------------------------------------------------------

set -e # Exit immediately if a command exits with a non-zero status.

#-------------------------------------------------------
# Helper Functions
#-------------------------------------------------------

# Function to print a formatted header
print_header() {
    echo ""
    echo "============================================================"
    echo " $1"
    echo "============================================================"
}

#-------------------------------------------------------
# Main Update Logic
#-------------------------------------------------------

# 1. Update this repository
print_header "Updating az-arch Repository"
if git pull; then
    echo "Repository updated successfully."
else
    echo "Warning: Could not update the repository. Continuing with the script..."
fi

# 2. Update system packages using paru
print_header "Updating System & AUR Packages (paru)"
if command -v paru &> /dev/null; then
    paru -Syu --noconfirm
else
    echo "Warning: paru command not found. Skipping system package update."
    echo "Please install paru to enable this feature."
fi

# 3. Update Flatpak packages
print_header "Updating Flatpak Packages"
if command -v flatpak &> /dev/null; then
    flatpak update -y
else
    echo "Warning: flatpak command not found. Skipping Flatpak update."
fi

# 4. Update dots-hyprland
print_header "Updating dots-hyprland"
if [ -d "$HOME/dots-hyprland" ]; then
    cd "$HOME/dots-hyprland" && git pull && ./install.sh --skip-hyprland -c -f
    echo "dots-hyprland updated successfully."
else
    echo "Warning: dots-hyprland directory not found. Skipping dots-hyprland update."
    echo "Please install dots-hyprland first if you wish to update it."
fi

# 5. Save updated configs back to the repository
print_header "Saving Updated Configurations"
if [ -f "./sync_configs.sh" ]; then
    ./sync_configs.sh save
else
    echo "Warning: sync_configs.sh not found. Skipping configuration save."
fi

#-------------------------------------------------------
# Finalization
#-------------------------------------------------------
print_header "System update process has finished."