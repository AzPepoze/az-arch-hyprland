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

install_reflector_and_enable_timer() {
    echo "Installing reflector..."
    paru -S --noconfirm reflector

    echo "Enabling reflector.timer..."
    sudo systemctl enable reflector.timer

    echo "Starting reflector.timer..."
    sudo systemctl start reflector.timer

    echo "Reflector installation and timer setup complete."
}

