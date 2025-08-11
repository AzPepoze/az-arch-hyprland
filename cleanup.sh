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
        paru -Sccd --noconfirm
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

cleanup_journal_logs() {
    echo
    echo "============================================================="
    echo " Cleaning Up Journal Logs"
    echo "============================================================="
    echo "Vacuuming journal logs to keep the last 3 days..."
    sudo journalctl --vacuum-time=3d
}

cleanup_coredumps() {
    echo
    echo "============================================================="
    echo " Cleaning Up Systemd Coredumps"
    echo "============================================================="
    echo "Removing all coredump files..."
    sudo find /var/lib/systemd/coredump/ -maxdepth 1 -type f -delete
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
    cleanup_journal_logs
    cleanup_coredumps
}

run_cleanup