#!/bin/bash

# --- Script to select a GRUB entry and reboot into it ---
# Author: A helpful AI
# Version: 1.1

# --- Step 1: Prerequisite Check ---
# This script requires GRUB to be configured to look for a saved entry.
# We check /etc/default/grub for the line 'GRUB_DEFAULT=saved'.
GRUB_CONFIG_FILE="/etc/default/grub"
if ! grep -q -E "^\s*GRUB_DEFAULT=saved\s*$" "$GRUB_CONFIG_FILE"; then
    echo -e "\e[1;31mERROR: Your GRUB configuration is not ready for this script.\e[0m"
    echo "This script requires 'GRUB_DEFAULT=saved' to be set in $GRUB_CONFIG_FILE."
    echo ""
    echo "Please do the following:"
    echo "1. Edit the file: sudo nano $GRUB_CONFIG_FILE"
    echo "2. Change the line 'GRUB_DEFAULT=0' (or similar) to 'GRUB_DEFAULT=saved'"
    echo "3. Save the file and run: sudo grub-mkconfig -o /boot/grub/grub.cfg"
    echo "4. Rerun this script after making the changes."
    exit 1
fi

# --- Step 2: Get Boot Entries ---
# We find all lines starting with 'menuentry', use awk to extract the title
# which is the text between the first and second single quotes.
GRUB_CFG="/boot/grub/grub.cfg"
mapfile -t entries < <(grep "^menuentry" "$GRUB_CFG" | awk -F"'" '{print $2}')

if [ ${#entries[@]} -eq 0 ]; then
    echo -e "\e[1;31mError: Could not find any boot entries in $GRUB_CFG\e[0m"
    exit 1
fi

# --- Step 3: Display Menu and Get User Choice ---
echo -e "\e[1;36mPlease select the OS to boot into for the next restart:\e[0m"

# The PS3 variable is the prompt used by the 'select' command.
PS3=$'\n'"Enter a number (or Ctrl+C to cancel): "

select choice in "${entries[@]}" "Quit"; do
    # Handle the "Quit" option
    if [[ "$choice" == "Quit" ]]; then
        echo "Operation cancelled."
        exit 0
    fi

    # Handle an invalid number
    if [ -z "$choice" ]; then
        echo -e "\e[1;33mInvalid selection. Please try again.\e[0m"
        continue
    fi

    # --- Step 4: Confirm and Execute ---
    # A valid choice was made, so we break out of the menu loop.
    echo -e "\nYou have selected to reboot into: \e[1;32m$choice\e[0m"
    read -p "Are you sure you want to proceed? (y/N) " confirm

    if [[ "$confirm" =~ ^[yY]$ ]]; then
        echo "Setting GRUB to boot '$choice' on the next restart..."
        
        # Use sudo to set the one-time boot entry
        sudo grub-reboot "$choice"
        
        # Check if the previous command succeeded before rebooting
        if [ $? -eq 0 ]; then
            echo -e "\e[1;32mSuccess! Rebooting now...\e[0m"
            reboot
        else
            echo -e "\e[1;31mError: The 'sudo grub-reboot' command failed. Please check your permissions.\e[0m"
            echo "Not rebooting."
            exit 1
        fi
    else
        echo "Reboot cancelled by user."
        exit 0
    fi
    break
done