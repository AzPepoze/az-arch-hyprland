#!/bin/bash

#-------------------------------------------------------
# MX002 Tablet Driver Installer
#-------------------------------------------------------

install_mx002_driver() {
    echo "Installing MX002 Tablet Driver..."

    # Check for Rust/Cargo
    if ! command -v cargo &> /dev/null; then
        echo "Rust is not installed. Installing rustup..."
        if ! command -v curl &> /dev/null; then
            echo "Error: curl is required to install rustup but it's not installed."
            echo "Please install curl and try again."
            return 1
        fi
        # Install rustup non-interactively
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        # Add cargo to PATH for the current session
        source "$HOME/.cargo/env"
    else
        echo "Rust is already installed."
    fi

    
    rm -rf "$HOME/mx002_linux_driver" 2>/dev/null

    local repo_url="https://github.com/marvinbelfort/mx002_linux_driver"
    local clone_dir=$(mktemp -d)"/mx002_linux_driver"

    if [ -d "$clone_dir" ]; then
        echo "Directory $clone_dir already exists. Skipping clone."
    else
        echo "Cloning $repo_url..."
        if ! git clone "$repo_url" "$clone_dir"; then
            echo "Error: Failed to clone the repository."
            return 1
        fi
    fi
    
    cd "$clone_dir"
    
    echo "Building driver with Cargo..."
    if cargo build --release; then
        echo "Driver built successfully."
        local built="$clone_dir/target/release"
        if [ -d "$built" ]; then
            echo "Moving driver binary to $clone_dir/"
            mv "$built" "$HOME/mx002_linux_driver"
            echo "Driver is located at $clone_dir"
            echo "NOTE: You may need to run it with sudo."
        else
            echo "Error: Built driver not found at the expected location."
        fi
    else
        echo "Error: Failed to build the driver."
        cd "$repo_dir" # Return to original script directory
        return 1
    fi
    
    cd "$repo_dir" # Return to original script directory
    echo "MX002 Tablet Driver installation process finished."
}
