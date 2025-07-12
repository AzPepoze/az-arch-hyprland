#!/bin/bash

#-------------------------------------------------------
# Update az-arch repository
#-------------------------------------------------------
echo "Updating az-arch repository..."
git pull
echo "az-arch repository has been updated successfully."
echo

#-------------------------------------------------------
# Update HyDE
#-------------------------------------------------------
echo "Updating HyDE..."
if [ -d "$HOME/HyDE" ]; then
    (
        cd "$HOME/HyDE/Scripts" || {
            echo "Error: Failed to navigate into ~/HyDE/Scripts"
            exit 1
        }

        echo "Pulling the latest changes for HyDE..."
        git pull

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
