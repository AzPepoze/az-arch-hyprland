#!/bin/bash

#-------------------------------------------------------
# Group: CLI Tools
#-------------------------------------------------------

install_gemini_cli() {
    if ! command -v pnpm &> /dev/null; then
        _log ERROR "pnpm is not installed. Please install it first."
        if ask_yes_no "Do you want to install pnpm now?"; then
            install_pnpm
        else
            echo "Skipping Gemini CLI installation."
            return 1
        fi
    fi
    echo "Installing Gemini CLI globally using pnpm..."
    pnpm add -g @google/gemini-cli
    _log SUCCESS "Gemini CLI installation completed successfully."
}

#-------------------------------------------------------
# Fisher Installation
#-------------------------------------------------------
install_fisher() {
    _log INFO "Installing Fisher (fish shell plugin manager)..."
    if fish -c "type fisher >/dev/null 2>&1"; then
        _log INFO "Fisher is already installed."
        return 0
    fi

    # Install fisher using a fish subshell
    fish -c "curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher"
    
    # Add fisher to path for future sessions
    fish -c "set -U fish_user_paths ~/.config/fish/functions $fish_user_paths"

    _log SUCCESS "Fisher installed. It will be available in new terminal sessions."
}

#-------------------------------------------------------
# jq Installation
#-------------------------------------------------------
install_jq() {
    echo "Installing jq..."
    install_paru_package "jq" "jq"
    _log SUCCESS "jq installation completed successfully."
}

#-------------------------------------------------------
# Git Credential Management Setup
#-------------------------------------------------------
setup_git_credential_management() {
    _log INFO "Setting up Git Credential Management..."
    echo "Installing git-credential-manager..."
    paru -S --needed --noconfirm git-credential-manager || { _log ERROR "Failed to install git-credential-manager."; return 1; }
    
    echo "Configuring Git credential helper..."
    git config --global credential.helper manager || { _log ERROR "Failed to configure credential.helper."; return 1; }
    
    echo "Configuring Git credential store..."
    git config --global credential.credentialStore secretservice || { _log ERROR "Failed to configure credential.credentialStore."; return 1; }
    
    _log SUCCESS "Git Credential Management setup completed successfully."
}

#-------------------------------------------------------
# System Utilities (CLI)
#-------------------------------------------------------

install_inotify_tools() {
     install_pacman_package "inotify-tools" "inotify-tools"
}

install_rclone() {
     install_paru_package "rclone" "rclone"
}

setup_rclone_gdrive() {
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

     mkdir -p ~/GoogleDrive

     rclone config

     _log SUCCESS "rclone configuration Google Drive finished."
}
