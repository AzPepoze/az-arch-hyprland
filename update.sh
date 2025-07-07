#!/bin/bash

#-------------------------------------------------------
# Update arch-setup repository
#-------------------------------------------------------
echo "Updating arch-setup repository..."
git pull
echo "arch-setup repository has been updated successfully."
echo

#-------------------------------------------------------
# Update HyDE
#-------------------------------------------------------
echo "Updating HyDE..."
if [ -d "$HOME/HyDE" ]; then
     (
          # Navigate to the HyDE scripts directory
          cd "$HOME/HyDE/Scripts" || {
               echo "Error: Failed to navigate into ~/HyDE/Scripts"
               exit 1
          }

          # Pull the latest changes from the repository
          echo "Pulling the latest changes for HyDE..."
          git pull

          # Run the installer script to apply updates
          echo "Running the HyDE installer..."
          ./install.sh
     )
     echo "HyDE update process completed."
else
     echo "Warning: HyDE directory not found at ~/HyDE. Skipping update."
     echo "You can install it using the main install.sh script."
fi

echo
echo "Update script has finished."
