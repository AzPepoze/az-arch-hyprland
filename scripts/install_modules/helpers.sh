#!/bin/bash

#-------------------------------------------------------
# Group: Helper Functions
#-------------------------------------------------------

# Logging functions
_log() {
    local type="$1"; shift
    local msg="$*"
    local color_red="\033[0;31m"
    local color_green="\033[0;32m"
    local color_yellow="\033[0;33m"
    local color_blue="\033[0;34m"
    local color_reset="\033[0m"

    case "$type" in
        INFO) echo -e "${color_blue}[INFO]${color_reset} $msg" ;;
        SUCCESS) echo -e "${color_green}[SUCCESS]${color_reset} $msg" ;;
        WARN) echo -e "${color_yellow}[WARN]${color_reset} $msg" ;;
        ERROR) echo -e "${color_red}[ERROR]${color_reset} $msg" >&2 ;;
        *) echo "$msg" ;;
    esac
}

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
