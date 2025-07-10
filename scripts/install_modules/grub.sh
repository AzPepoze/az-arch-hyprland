#!/bin/bash

#-------------------------------------------------------
# Group: System Configuration - GRUB
#-------------------------------------------------------

_check_grub_file_exists() {
     if [ ! -f "/etc/default/grub" ]; then
          echo "Error: /etc/default/grub not found. Is GRUB installed?"
          return 1
     fi
     return 0
}

_regenerate_grub_config() {
     echo "Regenerating GRUB configuration..."
     sudo grub-mkconfig -o /boot/grub/grub.cfg
     echo "GRUB configuration updated successfully."
}

adjust_grub_menu() {
     echo "Adjusting GRUB menu resolution to 1920x1080x32..."
     _check_grub_file_exists || return 1
     local grub_file="/etc/default/grub"

     if sudo grep -q '^GRUB_GFXMODE=' "$grub_file"; then
          echo "Updating existing GRUB_GFXMODE setting."
          sudo sed -i 's/^GRUB_GFXMODE=.*/GRUB_GFXMODE=1920x1080x32/' "$grub_file"
     else
          echo "Adding new GRUB_GFXMODE setting."
          echo 'GRUB_GFXMODE=1920x1080x32' | sudo tee -a "$grub_file" >/dev/null
     fi

     _regenerate_grub_config
}

enable_os_prober() {
     install_pacman_package "os-prober" "os-prober"
     echo "Enabling os-prober in GRUB configuration..."
     _check_grub_file_exists || return 1
     local grub_file="/etc/default/grub"

     if sudo grep -q '#GRUB_DISABLE_OS_PROBER=true' "$grub_file"; then
          echo "Uncommenting and setting GRUB_DISABLE_OS_PROBER to false."
          sudo sed -i 's/#GRUB_DISABLE_OS_PROBER=true/GRUB_DISABLE_OS_PROBER=false/' "$grub_file"
     elif ! sudo grep -q '^GRUB_DISABLE_OS_PROBER=' "$grub_file"; then
          echo "Adding GRUB_DISABLE_OS_PROBER=false to the configuration."
          echo 'GRUB_DISABLE_OS_PROBER=false' | sudo tee -a "$grub_file" >/dev/null
     else
          echo "GRUB_DISABLE_OS_PROBER is already configured."
     fi

     _regenerate_grub_config
}
