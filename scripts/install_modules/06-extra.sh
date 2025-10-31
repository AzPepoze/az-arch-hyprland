#!/bin/bash

#-------------------------------------------------------
# Android Emulation
#-------------------------------------------------------
install_waydroid() {
    echo "Installing Waydroid..."
    paru -S --noconfirm waydroid
    echo "If you experience dragging issues in Waydroid, try running: waydroid prop set persist.waydroid.fake_touch '*.*' or use waydroid-helper to configure it."
}

install_waydroid_helper() {
    echo "Installing Waydroid Helper..."
    paru -S --needed --noconfirm waydroid-helper
}

install_waydroid_extra_script() {
    echo "Installing Waydroid Extra Script..."
    cd /tmp
    git clone https://github.com/casualsnek/waydroid_script
    cd waydroid_script
    python3 -m venv venv
    venv/bin/pip install -r requirements.txt
    sudo venv/bin/python3 main.py
    cd ~
    sudo rm -rf /tmp/waydroid_script
}

#-------------------------------------------------------
# Virtualization
#-------------------------------------------------------
install_virt_packages() {
    echo "Installing virtualization packages..."
    paru -S --needed --noconfirm libvirt virt-manager qemu-full dnsmasq dmidecode edk2-ovmf
    echo "Enabling libvirtd.service..."
    sudo systemctl enable --now libvirtd.service
    echo "Adding current user to libvirt group..."
    sudo usermod -aG libvirt,kvm $USER

    echo "Checking for KVM support..."
    if [ -e "/dev/kvm" ]; then
        echo "KVM is available. Virtualization will be hardware-accelerated."
    else
        echo "KVM is not available. Virtualization might be slower."
        echo "Please ensure your CPU supports virtualization (Intel VT-x/AMD-V) and it's enabled in BIOS/UEFI."
        echo "You might also need to load the 'kvm_intel' or 'kvm_amd' kernel modules manually."
    fi
    echo "Tip: If you want to boot Windows from another partition, you can add the whole drive (e.g., /dev/sda) to your virtual machine, not just the partition."
    echo "Virtualization packages installation complete."
}

#-------------------------------------------------------
# Automation
#-------------------------------------------------------
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

#-------------------------------------------------------
# Extra Kernel Modules
#-------------------------------------------------------
install_v4l2loopback() {
    install_paru_package "v4l2loopback-dkms" "v4l2loopback"
    echo "Adding v4l2loopback to /etc/modules-load.d/v4l2loopback.conf to load on boot..."
    echo "v4l2loopback" | sudo tee /etc/modules-load.d/v4l2loopback.conf > /dev/null
    _log SUCCESS "v4l2loopback module configuration completed."
}
