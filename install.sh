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
# Install Hyprland Dots
#-------------------------------------------------------
install_end4_hyprland_dots() {
    echo "Installing Hyprland Dots..."
    bash -c "$(curl -s https://end-4.github.io/dots-hyprland-wiki/setup.sh)"
    echo "Hyprland Dots installation finished."
}

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
    echo " 9) Install end-4's Hyprland Dots"
    echo " 10) Install HyDE Dots"
    echo " 11) Install the Hyprspace plugin for Hyprland"
    echo " 12) Copy new Hyprland config files to ~/.config/hypr/"
    echo " 13) Copy old Hyprland config files to ~/.config/hypr/"
    echo " 14) Install Quickshell"
    echo " 15) Copy local Quickshell config files to ~/.config/quickshell/"
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
    echo " 37) Install Ulauncher"
    echo " 38) Install Ulauncher Catppuccin Theme"
    echo
    echo "--- Theming & Customization ---"
    echo " 39) Install Wallpaper Engine"
    echo " 40) Install Linux Wallpaper Engine GUI (Manual Build)"
    echo " 41) Install SDDM Astronaut Theme"
    echo "------------------------------------------------------------"
    echo " 42) Exit"
    echo "------------------------------------------------------------"
}

main_menu() {
    while true; do
        show_menu
        read -p "Enter your choice [1-42]: " choice

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
            if ask_yes_no "Install Hyprland Dots?"; then install_end4_hyprland_dots; fi
            
            if ask_yes_no "Install HyDE Dots?"; then install_hyde_dots; fi
            if ask_yes_no "Install the Hyprspace plugin for Hyprland?"; then install_hyprspace; fi
            echo "Which Hyprland config files would you like to copy?"
            echo "  1) New config files"
            echo "  2) Old config files"
            echo "  3) None"
            read -p "Enter your choice [1-3]: " hypr_config_choice
            case $hypr_config_choice in
                1) copy_new_hypr_configs ;;
                2) copy_old_hypr_configs ;;
                3) echo "Skipping Hyprland config file copy." ;;
                *) echo "Invalid choice. Skipping Hyprland config file copy." ;;
            esac
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
            if ask_yes_no "Install Ulauncher?"; then install_ulauncher; fi
            if ask_yes_no "Install Ulauncher Catppuccin Theme?"; then install_ulauncher_catppuccin_theme; fi
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
        9) install_end4_hyprland_dots ;;
        10) install_hyde_dots ;;
        11) install_hyprspace ;;
        12) copy_new_hypr_configs ;;
        13) copy_old_hypr_configs ;;
        14) install_quickshell ;;
        15) copy_quickshell_configs ;;
        15) install_systemd_oomd ;;
        16) install_ananicy_cpp ;;
        17) install_inotify_tools ;;
        18) install_power_options ;;
        19) install_mission_center ;;
        20) install_rclone ;;
        21) setup_rclone_gdrive ;;
        22) fix_vscode_permissions ;;
        23) install_gemini_cli ;;
        24) install_vesktop ;;
        25) setup_vesktop_rpc ;;
        26) clone_thai_fonts_css ;;
        27) install_youtube_music ;;
        28) install_steam ;;
        29) install_ms_edge ;;
        30) install_easyeffects ;;
        31) install_zen_browser ;;
        32) install_pinta ;;
        33) install_switcheroo ;;
        34) install_bleachbit ;;
        35) install_qdirstat ;;
        36) install_flatseal ;;
        37) install_gwenview ;;
        38) install_ulauncher ;;
        39) install_ulauncher_catppuccin_theme ;;
        40) install_wallpaper_engine ;;
        41) install_wallpaper_engine_gui_manual ;;
        42) install_sddm_theme ;;
        43)
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
