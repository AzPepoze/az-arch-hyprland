#!/bin/bash

install_virt_packages() {
    echo "Installing virtualization packages..."
    paru -S --noconfirm libvirt virt-manager qemu-full dnsmasq dmidecode edk2-ovmf
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
