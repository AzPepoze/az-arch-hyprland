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
    echo " 14) Install inotify-tools"
    echo " 15) Install Power Options (power-options-gtk-git)"
    echo " 16) Install Mission Center"
    echo " 17) Install rclone"
    echo " 18) Setup Google Drive with rclone"
    echo " 19) Fix VSCode Insiders permissions"
    echo
    echo "--- CLI Tools ---"
    echo " 20) Install Gemini CLI"
    echo
    echo "--- Applications ---"
    echo " 21) Install Vesktop (requires Flatpak)"
    echo " 22) Set up Vencord/Vesktop Activity Status"
    echo " 23) Clone thai_fonts.css for Vesktop"
    echo " 24) Install YouTube Music"
    echo " 25) Install Steam"
    echo " 26) Install Microsoft Edge (Dev)"
    echo " 27) Install Zen Browser (requires Flatpak)"
    echo " 28) Install Pinta"
    echo " 29) Install Switcheroo"
    echo " 30) Install BleachBit"
    echo " 31) Install QDirStat"
    echo " 32) Install Flatseal (requires Flatpak)"
    echo
    echo "--- Theming & Customization ---"
    echo " 33) Install Wallpaper Engine"
    echo " 34) Install Linux Wallpaper Engine GUI (Manual Build)"
    echo " 35) Install SDDM Astronaut Theme"
    echo "------------------------------------------------------------"
    echo " 36) Exit"
    echo "------------------------------------------------------------"
}

main_menu() {
    while true; do
        show_menu
        read -p "Enter your choice [1-35]: " choice

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
            if ask_yes_no "Install Zen Browser?"; then install_zen_browser; fi
            if ask_yes_no "Install Pinta?"; then install_pinta; fi
            if ask_yes_no "Install Switcheroo?"; then install_switcheroo; fi
            if ask_yes_no "Install BleachBit?"; then install_bleachbit; fi
            if ask_yes_no "Install QDirStat?"; then install_qdirstat; fi
            if ask_yes_no "Install Flatseal?"; then install_flatseal; fi
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
        14) install_inotify_tools ;;
        15) install_power_options ;;
        16) install_mission_center ;;
        17) install_rclone ;;
        18) setup_rclone_gdrive ;;
        19) fix_vscode_permissions ;;
        20) install_gemini_cli ;;
        21) install_vesktop ;;
        22) setup_vesktop_rpc ;;
        23) clone_thai_fonts_css ;;
        24) install_youtube_music ;;
        25) install_steam ;;
        26) install_ms_edge ;;
        27) install_zen_browser ;;
        28) install_pinta ;;
        29) install_switcheroo ;;
        30) install_bleachbit ;;
        31) install_qdirstat ;;
        32) install_flatseal ;;
        33) install_wallpaper_engine ;;
        34) install_wallpaper_engine_gui_manual ;;
        35) install_sddm_theme ;;
        36)
            echo "Exiting script. Goodbye!"
            break
            ;;
        *)
            echo "Invalid option '$choice'. Please try again."
            ;;
        esac

        if [[ "$choice" != "35" ]]; then
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
