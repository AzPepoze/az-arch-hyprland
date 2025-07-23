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
# Data-Driven Menu Configuration
#-------------------------------------------------------
menu_items=()
menu_funcs=()
menu_types=()

add_menu_item() {
    local type="$1"
    local func="$2"
    local text="$3"
    menu_items+=("$text")
    menu_funcs+=("$func")
    menu_types+=("$type")
}

populate_menu_data() {
    menu_items=()
    menu_funcs=()
    menu_types=()

    add_menu_item "header" "" "--- Installation Suite ---"
    add_menu_item "special" "run_installation_suite_all" "Install ALL components (including optional)"
    add_menu_item "special" "run_installation_suite_essential" "Install ALL essential components (excluding optional)"

    add_menu_item "header" "" "\n--- Core System & Package Management ---"
    add_menu_item "essential" "install_paru" "Install paru (AUR Helper)"
    add_menu_item "essential" "install_flatpak" "Install the Flatpak package manager"
    add_menu_item "essential" "install_fuse" "Install FUSE (Filesystem in Userspace)"
    add_menu_item "essential" "install_npm" "Install npm"
    add_menu_item "essential" "install_pnpm" "Install pnpm"

    add_menu_item "header" "" "\n--- System Configuration - GRUB ---"
    add_menu_item "essential" "adjust_grub_menu" "Adjust GRUB menu resolution (1920x1080)"
    add_menu_item "essential" "enable_os_prober" "Install & Enable os-prober for GRUB"
    add_menu_item "essential" "select_and_install_catppuccin_grub_theme" "Install/Change Catppuccin Theme for GRUB"

    add_menu_item "header" "" "\n--- Desktop Environment - Hyprland ---"
    add_menu_item "essential" "install_end4_hyprland_dots" "Install end-4's Hyprland Dots"

install_end4_hyprland_dots() {
    echo "Installing end-4's Hyprland Dots..."
    cd ~
    git clone https://github.com/end-4/dots-hyprland
    cd dots-hyprland
    ./install.sh
    echo "end-4's Hyprland Dots installation complete."
}
    add_menu_item "essential" "install_hyprspace" "Install the Hyprspace plugin for Hyprland"
    add_menu_item "essential" "install_quickshell" "Install Quickshell"
    add_menu_item "essential" "copy_quickshell_configs" "Copy local Quickshell config files to ~/.config/quickshell/"

    add_menu_item "header" "" "\n--- Theming & Customization ---"
    add_menu_item "special" "load_all_configs" "Load all configurations from repo to system"
    add_menu_item "optional" "install_wallpaper_engine" "Install Linux Wallpaper Engine"
    add_menu_item "optional" "install_wallpaper_engine_gui_manual" "Install Linux Wallpaper Engine GUI (Manual Build)"
    add_menu_item "essential" "install_sddm_theme" "Install SDDM Astronaut Theme"
    add_menu_item "essential" "install_catppuccin_fish_theme" "Install Catppuccin Fish Theme"

    add_menu_item "header" "" "\n--- System Utilities ---"
    add_menu_item "essential" "install_systemd_oomd" "Install systemd-oomd.service"
    add_menu_item "essential" "install_ananicy_cpp" "Install ananicy-cpp"
    add_menu_item "essential" "install_inotify_tools" "Install inotify-tools"
    add_menu_item "essential" "install_power_options" "Install Power Options (power-options-gtk-git)"
    add_menu_item "essential" "install_mission_center" "Install Mission Center"
    add_menu_item "essential" "fix_vscode_permissions" "Fix VSCode Insiders permissions"

    add_menu_item "header" "" "\n--- Applications ---"
    add_menu_item "essential" "install_vesktop" "Install Vesktop (requires Flatpak)"
    add_menu_item "essential" "setup_vesktop_rpc" "Set up Vencord/Vesktop Activity Status"
    add_menu_item "essential" "install_youtube_music" "Install YouTube Music"
    add_menu_item "essential" "install_steam" "Install Steam"
    add_menu_item "essential" "install_pinta" "Install Pinta"
    add_menu_item "essential" "install_switcheroo" "Install Switcheroo"
    add_menu_item "essential" "install_bleachbit" "Install BleachBit"
    add_menu_item "essential" "install_qdirstat" "Install QDirStat"
    add_menu_item "essential" "install_flatseal" "Install Flatseal (requires Flatpak)"
    add_menu_item "essential" "install_gwenview" "Install Gwenview"
    add_menu_item "essential" "install_ulauncher" "Install Ulauncher"
    add_menu_item "essential" "install_ulauncher_catppuccin_theme" "Install Ulauncher Catppuccin Theme"

    add_menu_item "header" "" "\n--- System Utilities (Optional) ---"
    add_menu_item "optional" "install_rclone" "Install rclone"
    add_menu_item "optional" "setup_rclone_gdrive" "Setup Google Drive with rclone"

    add_menu_item "header" "" "\n--- CLI Tools (Optional) ---"
    add_menu_item "optional" "install_gemini_cli" "Install Gemini CLI"
    add_menu_item "optional" "install_fisher" "Install Fisher (fish shell plugin manager)"

    add_menu_item "header" "" "\n--- Applications (Optional) ---"
    add_menu_item "optional" "copy_thai_fonts_css" "Copy thai_fonts.css for Vesktop"
    add_menu_item "optional" "install_ms_edge" "Install Microsoft Edge (Dev)"
    add_menu_item "optional" "install_easyeffects" "Install EasyEffects (requires Flatpak)"
    add_menu_item "optional" "install_zen_browser" "Install Zen Browser (requires Flatpak)"
    add_menu_item "optional" "install_handbrake" "Install HandBrake"
}

#-------------------------------------------------------
# Specific Handlers
#-------------------------------------------------------
load_all_configs() {
    echo "Loading all configurations from repository to system..."
    if [ -f "$repo_dir/sync_configs.sh" ]; then
        bash "$repo_dir/sync_configs.sh" load
    else
        echo "Error: sync_configs.sh not found!"
    fi
    echo "Config sync process finished."
}

select_and_install_catppuccin_grub_theme() {
    local flavors=("mocha" "latte" "frappe" "macchiato")
    echo "Please select a Catppuccin flavor for GRUB:"
    select flavor in "${flavors[@]}"; do
        if [[ " ${flavors[*]} " =~ " ${flavor} " ]]; then
            echo "You selected: $flavor"
            install_catppuccin_grub_theme "$flavor"
            break
        else
            echo "Invalid option. Please try again."
        fi
    done
}

#-------------------------------------------------------
# Installation Suite Logic
#-------------------------------------------------------
run_installation_suite() {
    local mode=$1
    local title
    if [[ "$mode" == "all" ]]; then
        title="full installation process (including optional components)"
    else
        title="essential components installation"
    fi

    echo "Starting $title..."
    echo "You will be asked to confirm each step."

    for i in "${!menu_items[@]}"; do
        local type="${menu_types[i]}"
        local func="${menu_funcs[i]}"
        local item="${menu_items[i]}"

        if [[ "$type" == "essential" || ("$type" == "optional" && "$mode" == "all") || "$type" == "special" ]]; then
            # Skip confirmation for special suite runners
            if [[ "$func" == "run_installation_suite_all" || "$func" == "run_installation_suite_essential" ]]; then
                continue
            fi

            if ask_yes_no "${item}?"; then
                if declare -f "$func" >/dev/null; then
                    "$func"
                else
                    echo "Error: Function '$func' not found."
                fi
            fi
        fi
    done

    echo "Installation suite finished."
}

run_installation_suite_all() {
    run_installation_suite "all"
}

run_installation_suite_essential() {
    run_installation_suite "essential"
}

#-------------------------------------------------------
# Main Logic
#-------------------------------------------------------
show_menu() {
    clear
    echo "------------------------------------------------------------"
    echo " Az Arch Setup Script - Main Menu"
    echo "------------------------------------------------------------"
    echo "Please select an option:"

    local option_num=1
    for i in "${!menu_items[@]}"; do
        if [[ "${menu_types[i]}" == "header" ]]; then
            echo -e "${menu_items[i]}"
        else
            printf " %2d) %s\n" "$option_num" "${menu_items[i]}"
            ((option_num++))
        fi
    done

    echo "------------------------------------------------------------"
    echo " $(($option_num))) Exit"
    echo "------------------------------------------------------------"
}

main_menu() {
    populate_menu_data

    while true; do
        show_menu

        local option_count=0
        for type in "${menu_types[@]}"; do
            if [[ "$type" != "header" ]]; then
                ((option_count++))
            fi
        done
        local exit_option=$((option_count + 1))

        read -p "Enter your choice [1-$exit_option]: " choice
        echo "------------------------------------------------------------"

        if ! [[ "$choice" =~ ^[0-9]+$ ]]; then
            echo "Invalid input. Please enter a number."
        elif ((choice > 0 && choice <= option_count)); then
            local current_option=0
            local target_index=-1
            for i in "${!menu_types[@]}"; do
                if [[ "${menu_types[i]}" != "header" ]]; then
                    ((current_option++))
                    if ((current_option == choice)); then
                        target_index=$i
                        break
                    fi
                fi
            done

            if ((target_index != -1)); then
                local func_to_run="${menu_funcs[target_index]}"
                if declare -f "$func_to_run" >/dev/null; then
                    "$func_to_run"
                else
                    echo "Error: Function '$func_to_run' not found."
                fi
            fi
        elif ((choice == exit_option)); then
            echo "Exiting script. Goodbye!"
            break
        else
            echo "Invalid option '$choice'. Please try again."
        fi

        if ((choice != exit_option)); then
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