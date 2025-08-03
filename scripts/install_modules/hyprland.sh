#!/bin/bash

#-------------------------------------------------------
# Group: Desktop Environment - Hyprland
#-------------------------------------------------------

install_end4_hyprland_dots() {
    echo "Installing end-4's Hyprland Dots..."
    cd ~
    git clone https://github.com/end-4/dots-hyprland
    cd dots-hyprland
    ./install.sh
    echo "end-4's Hyprland Dots installation complete."
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

