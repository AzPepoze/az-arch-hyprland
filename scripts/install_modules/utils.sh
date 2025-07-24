#!/bin/bash

#-------------------------------------------------------
# Group: System Utilities
#-------------------------------------------------------

install_inotify_tools() {
     install_pacman_package "inotify-tools" "inotify-tools"
}

install_power_options() {
     install_paru_package "power-options-gtk-git" "Power Options"
}

install_mission_center() {
     install_paru_package "mission-center" "Mission Center"
}

install_rclone() {
     install_paru_package "rclone" "rclone"
}

setup_rclone_gdrive() {
     _log INFO "Starting rclone configuration for Google Drive..."
     _log INFO "You will be guided through the setup process by rclone."
     _log INFO "When asked, choose 'n' for a new remote."
     _log INFO "Name it 'gdrive' (or a name of your choice)."
     _log INFO "Select the number corresponding to 'drive' (Google Drive)."
     _log INFO "Leave client_id and client_secret blank."
     _log INFO "Choose '1' for full access to all files."
     _log INFO "Leave root_folder_id and service_account_file blank."
     _log INFO "Choose 'n' for Edit advanced config."
     _log INFO "Choose 'y' for Use auto config."
     _log INFO "Follow the browser instructions to authorize rclone."
     _log INFO "Choose 'y' to confirm the new remote."
     _log INFO "Finally, choose 'q' to quit the configuration."

     mkdir -p ~/GoogleDrive

     rclone config

     _log SUCCESS "rclone configuration Google Drive finished."
}

fix_vscode_permissions() {
    _log INFO "Setting permissions for VSCode Insiders extension directory..."
    if [ -d "/usr/share/code-insiders" ]; then
        sudo chown -R "$(whoami)" /usr/share/code-insiders
        _log SUCCESS "Permissions set successfully."
    else
        _log ERROR "/usr/share/code-insiders directory not found. Is VSCode Insiders installed?"
        return 1
    fi
}