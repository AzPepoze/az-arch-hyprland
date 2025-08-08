#!/bin/bash

#-------------------------------------------------------
# Dependency Installation
#-------------------------------------------------------
install_dependencies() {
    echo "Checking for Python and python-pyqt6..."

    # Check for python
    if ! command -v python &> /dev/null
    then
        echo "Python not found. Installing..."
        sudo pacman -S --noconfirm python
    fi

    # Check for python-pyqt6
    if ! pacman -Qs python-pyqt6 &> /dev/null
    then
        echo "python-pyqt6 not found. Installing..."
        sudo pacman -S --noconfirm python-pyqt6
    fi

    echo "Dependencies check complete."
}

#-------------------------------------------------------
# Main Script Execution
#-------------------------------------------------------
install_dependencies

echo "Running install.py..."
python install.py
