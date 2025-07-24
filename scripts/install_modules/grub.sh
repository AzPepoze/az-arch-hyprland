#!/bin/bash

#-------------------------------------------------------
# Group: System Configuration - GRUB
#-------------------------------------------------------

_check_grub_file_exists() {
     if [ ! -f "/etc/default/grub" ]; then
          _log ERROR "/etc/default/grub not found. Is GRUB installed?"
          return 1
     fi
     return 0
}

_regenerate_grub_config() {
     _log INFO "Regenerating GRUB configuration..."
     sudo grub-mkconfig -o /boot/grub/grub.cfg
     _log SUCCESS "GRUB configuration updated successfully."
}

adjust_grub_menu() {
     _log INFO "Adjusting GRUB menu resolution to 1920x1080x32..."
     _check_grub_file_exists || return 1
     local grub_file="/etc/default/grub"

     if sudo grep -q '^GRUB_GFXMODE=' "$grub_file"; then
          _log INFO "Updating existing GRUB_GFXMODE setting."
          sudo sed -i 's/^GRUB_GFXMODE=.*/GRUB_GFXMODE=1920x1080x32/' "$grub_file"
     else
          _log INFO "Adding new GRUB_GFXMODE setting."
          echo 'GRUB_GFXMODE=1920x1080x32' | sudo tee -a "$grub_file" >/dev/null
     fi

     _regenerate_grub_config
}

enable_os_prober() {
     install_pacman_package "os-prober" "os-prober"
     _log INFO "Enabling os-prober in GRUB configuration..."
     _check_grub_file_exists || return 1
     local grub_file="/etc/default/grub"

     if sudo grep -q '#GRUB_DISABLE_OS_PROBER=true' "$grub_file"; then
          _log INFO "Uncommenting and setting GRUB_DISABLE_OS_PROBER to false."
          sudo sed -i 's/#GRUB_DISABLE_OS_PROBER=true/GRUB_DISABLE_OS_PROBER=false/' "$grub_file"
     elif ! sudo grep -q '^GRUB_DISABLE_OS_PROBER=' "$grub_file"; then
          _log INFO "Adding GRUB_DISABLE_OS_PROBER=false to the configuration."
          echo 'GRUB_DISABLE_OS_PROBER=false' | sudo tee -a "$grub_file" >/dev/null
     else
          _log INFO "GRUB_DISABLE_OS_PROBER is already configured."
     fi

     _regenerate_grub_config
}

install_catppuccin_grub_theme() {
    # Use the first argument as the theme flavor, default to 'mocha'
    local flavor=${1:-mocha}
    local capitalized_flavor="$(tr '[:lower:]' '[:upper:]' <<< ${flavor:0:1})${flavor:1}"

    _log INFO "Installing Catppuccin $capitalized_flavor theme for GRUB..."
    _check_grub_file_exists || return 1

    if ! command -v git &> /dev/null; then
        _log ERROR "git is not installed. Please install it first."
        return 1
    fi

    local theme_name="catppuccin-$flavor"
    local grub_themes_dir="/usr/share/grub/themes"
    local target_theme_dir="$grub_themes_dir/$theme_name"
    local grub_file="/etc/default/grub"
    local tmp_dir="/tmp/grub-catppuccin-theme"
    local theme_path="$target_theme_dir/theme.txt"

    # 1. Clone the repository
    _log INFO "Cloning Catppuccin GRUB theme repository..."
    if [ -d "$tmp_dir" ]; then
        rm -rf "$tmp_dir"
    fi
    git clone --depth 1 https://github.com/catppuccin/grub.git "$tmp_dir"
    if [ $? -ne 0 ]; then
        _log ERROR "Failed to clone the repository."
        return 1
    fi

    # 2. Copy the theme files from the correct path
    local source_theme_dir="$tmp_dir/src/catppuccin-$flavor-grub-theme"
    _log INFO "Source theme path is: $source_theme_dir"

    if [ ! -d "$source_theme_dir" ]; then
        _log ERROR "Source theme directory for '$flavor' not found after cloning!"
        rm -rf "$tmp_dir"
        return 1
    fi

    _log INFO "Installing theme to $target_theme_dir..."
    sudo mkdir -p "$target_theme_dir"
    sudo cp -r "$source_theme_dir/"* "$target_theme_dir/"
    if [ $? -ne 0 ]; then
        _log ERROR "Failed to copy theme files."
        rm -rf "$tmp_dir"
        return 1
    fi

    # 3. Set the GRUB_THEME variable
    _log INFO "Setting GRUB_THEME in $grub_file..."
    if sudo grep -q '^GRUB_THEME=' "$grub_file"; then
        sudo sed -i "s|^GRUB_THEME=.*|GRUB_THEME=\"$theme_path\"|" "$grub_file"
    else
        echo "GRUB_THEME=\"$theme_path\"" | sudo tee -a "$grub_file" >/dev/null
    fi

    # 4. Clean up the temporary directory
    _log INFO "Cleaning up temporary files..."
    rm -rf "$tmp_dir"

    # 5. Regenerate GRUB config
    _regenerate_grub_config

    _log SUCCESS "Catppuccin $capitalized_flavor GRUB theme installed and configured successfully."
}