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
     echo
     echo "Starting rclone configuration for Google Drive..."
     echo "You will be guided through the setup process by rclone."
     echo "When asked, choose 'n' for a new remote."
     echo "Name it 'gdrive' (or a name of your choice)."
     echo "Select the number corresponding to 'drive' (Google Drive)."
     echo "Leave client_id and client_secret blank."
     echo "Choose '1' for full access to all files."
     echo "Leave root_folder_id and service_account_file blank."
     echo "Choose 'n' for Edit advanced config."
     echo "Choose 'y' for Use auto config."
     echo "Follow the browser instructions to authorize rclone."
     echo "Choose 'y' to confirm the new remote."
     echo "Finally, choose 'q' to quit the configuration."
     echo

     mkdir -p ~/GoogleDrive

     rclone config

     echo "rclone configuration Google Drive finished."
}

fix_vscode_permissions() {
    echo "Setting permissions for VSCode Insiders extension directory..."
    if [ -d "/usr/share/code-insiders" ]; then
        sudo chown -R "$(whoami)" /usr/share/code-insiders
        echo "Permissions set successfully."
    else
        echo "Error: /usr/share/code-insiders directory not found. Is VSCode Insiders installed?" >&2
        return 1
    fi
}
