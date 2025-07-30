#!/bin/bash

#-------------------------------------------------------
# Cleanup Functions
#-------------------------------------------------------

cleanup_system_packages() {
    echo
    echo "============================================================="
    echo " Cleaning Up System Packages"
    echo "============================================================="
    if command -v paru &> /dev/null; then
        echo "Removing orphan packages..."
        paru -c --noconfirm

        echo
        echo "Cleaning package cache..."
        paru -Sc --noconfirm
        paru -Scc --noconfirm
    else
        echo "paru command not found. Skipping system package cleanup."
    fi
}

cleanup_flatpak() {
    echo
    echo "============================================================="
    echo " Cleaning Up Flatpak"
    echo "============================================================="
    if command -v flatpak &> /dev/null; then
        echo "Removing unused Flatpak runtimes..."
        flatpak uninstall --unused -y
    else
        echo "flatpak command not found. Skipping Flatpak cleanup."
    fi
}

#-------------------------------------------------------
# Main Execution
#-------------------------------------------------------
run_cleanup() {
    echo
    echo "============================================================="
    echo " Running System Cleanup"
    echo "============================================================="
    cleanup_system_packages
    cleanup_flatpak
}

run_cleanup