#!/bin/bash

#-------------------------------------------------------
# Group: Display Management
#-------------------------------------------------------

install_nwg_displays() {
    _log INFO "Installing nwg-displays for screen management..."
    install_paru_package "nwg-displays" "nwg-displays"
    _log SUCCESS "nwg-displays has been installed."
    
    if command -v nwg-displays &> /dev/null; then
        _log INFO "Launching nwg-displays..."
        # Redirect stdout and stderr to /dev/null to keep the terminal clean
        nwg-displays &>/dev/null &
        # Give it a moment to launch
        sleep 1
        echo ""
        _log INFO "Please configure your display settings in the nwg-displays window."
        _log INFO "Set the mode, resolution, and position for each monitor as needed."
        read -p "Once you are finished, press Enter in this terminal to continue..." 
    else
        _log ERROR "nwg-displays command not found after installation."
    fi
}
