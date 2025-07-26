#!/bin/bash

#-------------------------------------------------------
# System Services Module
#-------------------------------------------------------

# Install and enable systemd-oomd.service
install_systemd_oomd() {
    echo "Installing and enabling systemd-oomd.service..."
    sudo systemctl enable --now systemd-oomd.service
    _log SUCCESS "systemd-oomd.service installed and enabled."
}

# Install and enable ananicy-cpp
install_ananicy_cpp() {
    echo "Installing ananicy-cpp..."
    paru -S ananicy-cpp --noconfirm # --noconfirm is added for unattended installation
    echo "Enabling ananicy-cpp.service..."
    sudo systemctl enable --now ananicy-cpp.service
    _log SUCCESS "ananicy-cpp installed and enabled."
}