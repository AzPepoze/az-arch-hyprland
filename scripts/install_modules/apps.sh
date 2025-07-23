#!/bin/bash

#-------------------------------------------------------
# Group: Applications
#-------------------------------------------------------

install_vesktop() {
    install_flatpak_package "dev.vencord.Vesktop" "Vesktop"
}

setup_vesktop_rpc() {
    echo "Setting up Vencord/Vesktop Activity Status (for Flatpak)..."
    mkdir -p ~/.config/user-tmpfiles.d

    echo 'L %t/discord-ipc-0 - - - - .flatpak/dev.vencord.Vesktop/xdg-run/discord-ipc-0' >~/.config/user-tmpfiles.d/discord-rpc.conf
    systemctl --user enable --now systemd-tmpfiles-setup.service
    echo "Activity Status setup completed successfully."
}

copy_thai_fonts_css() {
        local source_file="$repo_dir/settings/thai_fonts.css"
    local dest_file="$HOME/.var/app/dev.vencord.Vesktop/config/vesktop/settings/quickCss.css"
    local dest_dir

    dest_dir=$(dirname "$dest_file")

    echo "Copying Thai fonts CSS for Vesktop..."

    if [ ! -f "$source_file" ]; then
        echo "Error: Source file not found at $source_file"
        return 1
    fi

    echo "Ensuring destination directory exists: $dest_dir"
    mkdir -p "$dest_dir"

    cp -v "$source_file" "$dest_file"
    echo "Successfully copied thai_fonts.css to the Vesktop directory."
}

install_youtube_music() {
    install_paru_package "youtube-music-bin" "YouTube Music"
}

install_steam() {
    install_paru_package "steam" "Steam"
}

install_ms_edge() {
    install_paru_package "microsoft-edge-dev-bin" "Microsoft Edge (Dev)"
}

install_easyeffects() {
    install_flatpak_package "com.github.wwmm.easyeffects" "EasyEffects"

    echo "Installing and enabling EasyEffects systemd service..."
    local service_source="$repo_dir/services/easyeffects.service"
    local service_dest="$HOME/.config/systemd/user/easyeffects.service"

    if [ ! -f "$service_source" ]; then
        echo "Error: EasyEffects service file not found at $service_source"
        return 1
    fi

    mkdir -p "$(dirname "$service_dest")"
    cp -v "$service_source" "$service_dest"

    systemctl --user enable --now easyeffects.service
    echo "EasyEffects service has been installed and started."
}

install_zen_browser() {
    install_flatpak_package "app.zen_browser.zen" "Zen Browser"
}

install_pinta() {
    install_pacman_package "pinta" "Pinta"
}

install_switcheroo() {
    install_paru_package "switcheroo" "Switcheroo"
}

install_bleachbit() {
    install_paru_package "bleachbit" "BleachBit"
}

install_gwenview() {
    install_paru_package "gwenview" "Gwenview"
}

install_qdirstat() {
    install_paru_package "qdirstat" "QDirStat"
}

install_ulauncher() {
    install_paru_package "ulauncher" "Ulauncher"
}

install_ulauncher_catppuccin_theme() {
    echo "Installing Catppuccin theme for Ulauncher..."
    curl https://raw.githubusercontent.com/catppuccin/ulauncher/main/install.py -fsSL | python3 - -f mocha -a pink
    echo "Catppuccin theme for Ulauncher installation attempted."
}

install_flatseal() {
    install_flatpak_package "com.github.tchx84.Flatseal" "Flatseal"
}

install_handbrake() {
    install_paru_package "handbrake" "HandBrake"
}
