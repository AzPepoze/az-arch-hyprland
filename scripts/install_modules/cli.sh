#!/bin/bash

#-------------------------------------------------------
# Group: CLI Tools
#-------------------------------------------------------

install_gemini_cli() {
    if ! command -v pnpm &> /dev/null; then
        echo "Error: pnpm is not installed. Please install it first."
        if ask_yes_no "Do you want to install pnpm now?"; then
            install_pnpm
        else
            echo "Skipping Gemini CLI installation."
            return 1
        fi
    fi
    echo "Installing Gemini CLI globally using pnpm..."
    pnpm add -g @google/gemini-cli
    echo "Gemini CLI installation completed successfully."
}
