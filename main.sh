#!/bin/bash
install_dependencies() {
    echo "Checking for Python and python-pyqt6..."

    if ! command -v python &> /dev/null; then
        echo "Python not found. Installing..."
        sudo pacman -S --noconfirm python
    fi

    if ! pacman -Qs python-pyqt6 &> /dev/null; then
        echo "python-pyqt6 not found. Installing..."
        sudo pacman -S --noconfirm python-pyqt6
    fi

    echo "Dependencies check complete."
}

install_dependencies

#-------------------------------------------------------
# Menu Display
#-------------------------------------------------------
show_menu() {
    echo "========================================"
    echo "  Az Arch Hyprland Management Script  "
    echo "========================================"
    echo "Please choose an option:"
    echo "  1) Run Installer"
    echo "  2) Open Configuration Editor"
    echo "  3) Load Dotfile Configurations"
    echo "  4) Update"
    echo "  5) Update (Full)"
    echo "  q) Quit"
    echo "----------------------------------------"
}

#-------------------------------------------------------
# Main Script Logic
#-------------------------------------------------------
while true; do
    show_menu
    read -p "Enter your choice [1-5, q]: " choice

    case $choice in
        1)
            echo "Starting Installer..."
            python scripts/install.py
            break
            ;;
        2)
            echo "Starting Configuration Editor..."
            python scripts/config.py
            break
            ;;
        3)
            echo "Loading configurations..."
            if [ -f "cli/load_configs.sh" ]; then
                bash cli/load_configs.sh --skip-cursor --skip-gpu
            else
                echo "Error: cli/load_configs.sh not found!"
            fi
            break
            ;;
        4)
            echo "Starting Update..."
            if [ -f "update.sh" ]; then
                bash update.sh --skip-cursor --skip-gpu
            else
                echo "Error: update.sh not found!"
            fi
            break
            ;;
        5)
            echo "Starting Full Update..."
            if [ -f "update.sh" ]; then
                bash update.sh --full
            else
                echo "Error: update.sh not found!"
            fi
            break
            ;;
        q|Q)
            echo "Exiting."
            break
            ;;
        *)
            echo "Invalid option. Please try again.
"
            ;;
    esac
done