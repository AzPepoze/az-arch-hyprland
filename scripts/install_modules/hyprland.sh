#!/bin/bash

#-------------------------------------------------------
# Group: Desktop Environment - Hyprland
#-------------------------------------------------------

install_end4_hyprland_dots() {
    _log INFO "Installing end-4's Hyprland Dots..."
    local target_dir="$HOME/dots-hyprland"

    if [ -d "$target_dir" ]; then
        _log WARN "Directory '$target_dir' already exists."
        if ask_yes_no "Do you want to remove the existing directory and reinstall?"; then
            _log INFO "Removing existing directory..."
            rm -rf "$target_dir"
        else
            _log INFO "Skipping installation of end-4's Hyprland Dots."
            return 0
        fi
    fi

    if git clone https://github.com/end-4/dots-hyprland "$target_dir"; then
        ( # Run in a subshell to avoid changing the main script's directory
            cd "$target_dir" || exit 1
            _log INFO "Running the installer script for dots-hyprland..."
            ./install.sh
        )
        _log SUCCESS "end-4's Hyprland Dots installation complete."
    else
        _log ERROR "Failed to clone the repository."
        return 1
    fi
}

copy_new_hypr_configs() {
    local config_src_dir="$repo_dir/configs/hypr"
    local config_dest_dir="$HOME/.config/hypr"

    if [ -d "$config_src_dir" ]; then
        echo "Ensuring destination directory exists: $config_dest_dir"
        mkdir -p "$config_dest_dir"

        echo "Copying all files and folders from $config_src_dir to $config_dest_dir..."
        cp -rfv "$config_src_dir"/. "$config_dest_dir/"
        _log SUCCESS "Configuration files copied successfully."
    else
        _log ERROR "Source directory '$config_src_dir' not found. Skipping config file copy."
    fi
}

copy_old_hypr_configs() {
    local config_src_dir="$repo_dir/configs/hypr-old"
    local config_dest_dir="$HOME/.config/hypr"

    if [ -d "$config_src_dir" ]; then
        echo "Ensuring destination directory exists: $config_dest_dir"
        mkdir -p "$config_dest_dir"

        echo "Copying .conf files from $config_src_dir to $config_dest_dir..."
        cp -v "$config_src_dir"/*.conf "$config_dest_dir/"
        _log SUCCESS "Configuration files copied successfully."
    else
        _log ERROR "Source directory '$config_src_dir' not found. Skipping config file copy."
    fi
}

