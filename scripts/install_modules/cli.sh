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
    }

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
# Git Credential Store Configuration
#-------------------------------------------------------
configure_git_credential_store() {
    echo "Configuring Git Credential Store to use secretservice..."
    git config --global credential.credentialStore secretservice
    _log SUCCESS "Git Credential Store configured successfully."
}