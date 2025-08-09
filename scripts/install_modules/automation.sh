#!/bin/bash

install_n8n() {
    echo "Installing n8n..."
    # Check if npm is installed
    if ! command -v pnpm &> /dev/null
    then
        echo "pnpm is not installed. Please install pnpm first."
        return 1
    fi

    # Install n8n globally using npm
    pnpm install -g n8n
    if [ $? -eq 0 ]; then
        echo "n8n installed successfully."
    else
        echo "Failed to install n8n."
        return 1
    fi

    echo "You can now run n8n by typing 'n8n' in your terminal."
    echo "For more information on n8n setup and usage, visit: https://docs.n8n.io/"
}
