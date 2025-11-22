#!/bin/bash

# This script manages a SYSTEM-WIDE systemd service for auto-mounting drives.

#-------------------------------------------------------
# Configuration
#-------------------------------------------------------
SERVICE_NAME="automount@.service"
SERVICE_INSTANCE="automount@$USER.service"
SERVICE_FILE_PATH="/etc/systemd/system/$SERVICE_NAME"

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
SERVICE_SCRIPT_PATH="$SCRIPT_DIR/../services/mount_drives.sh"

#-------------------------------------------------------
# Functions
#-------------------------------------------------------

enable_service() {
    echo ">> This will create a system-wide service to mount drives for user '$USER'."
    echo ">> You will be prompted for your password for 'sudo' commands."
    
    echo ">> Creating systemd service file at $SERVICE_FILE_PATH..."
    sudo tee "$SERVICE_FILE_PATH" > /dev/null << EOF
[Unit]
Description=Auto-mount drives for user %i
# Run after the udisks service is ready, ensuring devices are discovered.
After=udisks2.service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=$SERVICE_SCRIPT_PATH %i

[Install]
# We want the service to be available, but it will be started on login.
# The previous template implementation has issues with modern systemd.
# Let's try a more direct approach by tying it to the multi-user target.
WantedBy=multi-user.target
EOF

    if [ $? -ne 0 ]; then
        echo "ERROR: Failed to create systemd service file. Aborting."
        return 1
    fi

    echo ">> Reloading systemd daemon to recognize the new service..."
    sudo systemctl daemon-reload

    echo ">> Enabling the service for user '$USER' to start on login..."
    sudo systemctl enable "$SERVICE_INSTANCE"

    echo ">> Starting the service now for an initial mount..."
    sudo systemctl start "$SERVICE_INSTANCE"

    echo "OK: Successfully enabled and started the system-wide auto-mount service for user '$USER'."
}

disable_service() {
    echo ">> Disabling the service for user '$USER'..."
    sudo systemctl disable "$SERVICE_INSTANCE"

    echo ">> Stopping any running instance of the service..."
    sudo systemctl stop "$SERVICE_INSTANCE"

    echo ">> Removing template file..."
    sudo rm -f "$SERVICE_FILE_PATH"
    
    echo ">> Reloading systemd daemon..."
    sudo systemctl daemon-reload

    echo "OK: Successfully disabled the auto-mount service for user '$USER'."
}

#-------------------------------------------------------
# Interactive Menu
#-------------------------------------------------------
main() {
    echo "----------------------------------------"
    echo "  System Auto-Mount Service Manager"
    echo "----------------------------------------"
    echo "This script manages a systemd service to automatically mount"
    echo "drives for the current user ($USER) at login. This requires sudo."
    echo
    echo "Current Status:"
    if sudo systemctl is-enabled --quiet "$SERVICE_INSTANCE"; then
        echo "  - Service for user '$USER' is ENABLED."
    else
        echo "  - Service for user '$USER' is DISABLED."
    fi
    if [ -f "$SERVICE_FILE_PATH" ]; then
        echo "  - Service template file EXISTS."
    else
        echo "  - Service template file NOT FOUND."
    fi
    echo

    echo "1) Enable for user '$USER'"
    echo "2) Disable for user '$USER'"
    echo
    read -p "Choose an option (any other key to cancel): " choice

    case "$choice" in
        1)
            echo
            enable_service
            ;;
        2)
            echo
            disable_service
            ;;
        *)
            echo
            echo "INFO: Action cancelled."
            ;;
    esac
}

# Run the main function
main
