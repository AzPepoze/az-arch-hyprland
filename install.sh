#!/bin/bash

#-------------------------------------------------------
# Main Installer Script
#-------------------------------------------------------
repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
modules_dir="$repo_dir/scripts/install_modules"

#-------------------------------------------------------
# Source All Modules
#-------------------------------------------------------
while IFS= read -r -d '' module_file; do
    if [ -f "$module_file" ]; then
        source "$module_file"
    fi
done < <(find "$modules_dir" -name '*.sh' -print0)

#-------------------------------------------------------
# Main Logic
#-------------------------------------------------------
show_menu() {
    clear
    echo "------------------------------------------------------------"
    echo " AzP Arch Setup Script - Main Menu"
    echo "------------------------------------------------------------"
    echo "Please select an option:"
    echo
    echo "--- Installation Suite ---"
    echo " 1) Install ALL components and apply configurations"
    echo
    echo "--- Core System & Package Management ---"
    echo " 2) Install paru (AUR Helper)"
    echo " 3) Install the Flatpak package manager"
    echo " 4) Install FUSE (Filesystem in Userspace)"
    echo " 5) Install npm"
    echo " 6) Install pnpm"
    echo
    echo "--- System Configuration - GRUB ---"
    echo " 7) Adjust GRUB menu resolution (1920x1080)"
    echo " 8) Install & Enable os-prober for GRUB"
    echo
    echo "--- Desktop Environment - Hyprland ---"
    echo " 9) Install HyDE"
    echo " 10) Install the Hyprspace plugin for Hyprland"
    echo " 11) Copy local Hyprland config files to ~/.config/hypr/"
    echo " 12) Install Quickshell"
    echo " 13) Copy local Quickshell config files to ~/.config/quickshell/"
    echo
    echo "--- System Utilities ---"
    echo " 14) Install systemd-oomd.service"
    echo " 15) Install ananicy-cpp"
    echo " 16) Install inotify-tools"
    echo " 17) Install Power Options (power-options-gtk-git)"
    echo " 18) Install Mission Center"
    echo " 19) Install rclone"
    echo " 20) Setup Google Drive with rclone"
    echo " 21) Fix VSCode Insiders permissions"
    echo
    echo "--- CLI Tools ---"
    echo " 22) Install Gemini CLI"
    echo
    echo "--- Applications ---"
    echo " 23) Install Vesktop (requires Flatpak)"
    echo " 24) Set up Vencord/Vesktop Activity Status"
    echo " 25) Clone thai_fonts.css for Vesktop"
    echo " 26) Install YouTube Music"
    echo " 27) Install Steam"
    echo " 28) Install Microsoft Edge (Dev)"
    echo " 29) Install EasyEffects (requires Flatpak)"
    echo " 30) Install Zen Browser (requires Flatpak)"
    echo " 31) Install Pinta"
    echo " 32) Install Switcheroo"
    echo " 33) Install BleachBit"
    echo " 34) Install QDirStat"
    echo " 35) Install Flatseal (requires Flatpak)"
    echo " 36) Install Gwenview"
    echo
    echo "--- Theming & Customization ---"
    echo " 37) Install Wallpaper Engine"
    echo " 38) Install Linux Wallpaper Engine GUI (Manual Build)"
    echo " 39) Install SDDM Astronaut Theme"
    echo "------------------------------------------------------------"
    echo " 40) Exit"
    echo "------------------------------------------------------------"
}

main_menu() {
    while true; do
        show_menu
        read -p "Enter your choice [1-38]: " choice

        echo "------------------------------------------------------------"

        case $choice in
        1)
            echo "Starting full installation process..."
            echo "You will be asked to confirm each step."

            if ask_yes_no "Install paru (AUR Helper)?"; then install_paru; fi
            if ask_yes_no "Install Flatpak?"; then install_flatpak; fi
            if ask_yes_no "Install FUSE?"; then install_fuse; fi
            if ask_yes_no "Install npm?"; then install_npm; fi
            if ask_yes_no "Install pnpm?"; then install_pnpm; fi
            if ask_yes_no "Adjust GRUB menu resolution?"; then adjust_grub_menu; fi
            if ask_yes_no "Install & Enable os-prober for GRUB?"; then enable_os_prober; fi
            if ask_yes_no "Install HyDE?"; then install_hyde; fi
            if ask_yes_no "Install the Hyprspace plugin for Hyprland?"; then install_hyprspace; fi
            if ask_yes_no "Copy local Hyprland config files?"; then copy_hypr_configs; fi
            if ask_yes_no "Install Quickshell?"; then install_quickshell; fi
            if ask_yes_no "Copy local Quickshell config files?"; then copy_quickshell_configs; fi
            if ask_yes_no "Install systemd-oomd.service?"; then install_systemd_oomd; fi
            if ask_yes_no "Install ananicy-cpp?"; then install_ananicy_cpp; fi
            if ask_yes_no "Install inotify-tools?"; then install_inotify_tools; fi
            if ask_yes_no "Install Power Options?"; then install_power_options; fi
            if ask_yes_no "Install Mission Center?"; then install_mission_center; fi
            if ask_yes_no "Install rclone?"; then install_rclone; fi
            if ask_yes_no "Setup Google Drive with rclone?"; then setup_rclone_gdrive; fi
            if ask_yes_no "Fix VSCode Insiders permissions?"; then fix_vscode_permissions; fi
            if ask_yes_no "Install Gemini CLI?"; then install_gemini_cli; fi
            if ask_yes_no "Install Vesktop?"; then install_vesktop; fi
            if ask_yes_no "Set up Vencord/Vesktop Activity Status?"; then setup_vesktop_rpc; fi
            if ask_yes_no "Clone thai_fonts.css for Vesktop?"; then clone_thai_fonts_css; fi
            if ask_yes_no "Install YouTube Music?"; then install_youtube_music; fi
            if ask_yes_no "Install Steam?"; then install_steam; fi
            if ask_yes_no "Install Microsoft Edge (Dev)?"; then install_ms_edge; fi
            if ask_yes_no "Install EasyEffects?"; then install_easyeffects; fi
            if ask_yes_no "Install Zen Browser?"; then install_zen_browser; fi
            if ask_yes_no "Install Pinta?"; then install_pinta; fi
            if ask_yes_no "Install Switcheroo?"; then install_switcheroo; fi
            if ask_yes_no "Install BleachBit?"; then install_bleachbit; fi
            if ask_yes_no "Install QDirStat?"; then install_qdirstat; fi
            if ask_yes_no "Install Flatseal?"; then install_flatseal; fi
            if ask_yes_no "Install Gwenview?"; then install_gwenview; fi
            if ask_yes_no "Install Wallpaper Engine?"; then install_wallpaper_engine; fi
            if ask_yes_no "Install Linux Wallpaper Engine GUI (Manual Build)?"; then install_wallpaper_engine_gui_manual; fi
            if ask_yes_no "Install SDDM Astronaut Theme?"; then install_sddm_theme; fi

            echo "Full installation process finished."
            ;;
        2) install_paru ;;
        3) install_flatpak ;;
        4) install_fuse ;;
        5) install_npm ;;
        6) install_pnpm ;;
        7) adjust_grub_menu ;;
        8) enable_os_prober ;;
        9) install_hyde ;;
        10) install_hyprspace ;;
        11) copy_hypr_configs ;;
        12) install_quickshell ;;
        13) copy_quickshell_configs ;;
        14) install_systemd_oomd ;;
        15) install_ananicy_cpp ;;
        16) install_inotify_tools ;;
        17) install_power_options ;;
        18) install_mission_center ;;
        19) install_rclone ;;
        20) setup_rclone_gdrive ;;
        21) fix_vscode_permissions ;;
        22) install_gemini_cli ;;
        23) install_vesktop ;;
        24) setup_vesktop_rpc ;;
        25) clone_thai_fonts_css ;;
        26) install_youtube_music ;;
        27) install_steam ;;
        28) install_ms_edge ;;
        29) install_easyeffects ;;
        30) install_zen_browser ;;
        31) install_pinta ;;
        32) install_switcheroo ;;
        33) install_bleachbit ;;
        34) install_qdirstat ;;
        35) install_flatseal ;;
        36) install_gwenview ;;
        37) install_wallpaper_engine ;;
        38) install_wallpaper_engine_gui_manual ;;
        39) install_sddm_theme ;;
        40)
            echo "Exiting script. Goodbye!"
            break
            ;;
        *)
            echo "Invalid option '$choice'. Please try again."
            ;;
        esac

        if [[ "$choice" != "38" ]]; then
            echo "------------------------------------------------------------"
            read -p "Press Enter to return to the menu..."
        fi
    done
}

#-------------------------------------------------------
# Script Execution
#-------------------------------------------------------
echo "------------------------------------------------------------"
echo "This script will guide you through the installation of"
echo "various packages and configurations for your system."
echo "------------------------------------------------------------"

main_menu

echo "------------------------------------------------------------"
echo "The script has finished."
