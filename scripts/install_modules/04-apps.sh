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
    _log SUCCESS "Activity Status setup completed successfully."
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

install_vscode_insiders() {
    install_paru_package "code-insiders-bin" "VS Code Insiders"
}

fix_vscode_permissions() {
    echo "Attempting to fix permissions for VS Code Insiders..."
    local vscode_path="/usr/share/code-insiders"
    if [ -d "$vscode_path" ]; then
        sudo chown -R $(whoami):$(whoami) "$vscode_path"
        _log SUCCESS "Fixed permissions for VS Code Insiders at $vscode_path"
    else
        _log INFO "VS Code Insiders installation path $vscode_path not found. Skipping permission fix."
    fi
}

install_easyeffects() {
    install_flatpak_package "com.github.wwmm.easyeffects" "EasyEffects"

    echo "Installing and enabling EasyEffects systemd service..."
    local service_source="$repo_dir/services/easyeffects.service"
    local service_dest="$HOME/.config/systemd/user/easyeffects.service"

    if [ ! -f "$service_source" ]; then
        _log ERROR "EasyEffects service file not found at $service_source"
        return 1
    fi

    mkdir -p "$(dirname "$service_dest")"
    cp -v "$service_source" "$service_dest"

    systemctl --user enable --now easyeffects.service
    _log SUCCESS "EasyEffects service has been installed and started."
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

install_droidcam() {
    install_paru_package "droidcam" "Droidcam"
}

install_coolercontrol() {
    install_paru_package "coolercontrol-bin" "CoolerControl"
    echo "Enabling coolercontrold.service..."
    sudo systemctl enable --now coolercontrold.service
    _log SUCCESS "coolercontrold.service enabled."
}

install_power_options() {
     install_paru_package "power-options-gtk-git" "Power Options"
}

install_mission_center() {
     install_paru_package "mission-center" "Mission Center"
}

install_pavucontrol() {
    install_paru_package "pavucontrol" "Pavucontrol"
}
