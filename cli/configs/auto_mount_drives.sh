#!/bin/bash

# This script manages a systemd user service for auto-mounting drives,
# including the necessary Polkit rule for permissions.

#-------------------------------------------------------
# Configuration
#-------------------------------------------------------
SERVICE_NAME="automount.service"
SERVICE_FILE_PATH="$HOME/.config/systemd/user/$SERVICE_NAME"
POLKIT_RULE_PATH="/etc/polkit-1/rules.d/49-allow-udisks2-mount.rules"

# IMPORTANT: This path must be absolute. It points to the script the service will run.
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
SERVICE_SCRIPT_PATH="$SCRIPT_DIR/../services/mount_drives.sh"

#-------------------------------------------------------
# Functions
#-------------------------------------------------------

# Function to enable and start the systemd service.
enable_service() {
    # Step 1: Check for and create the Polkit rule if it doesn't exist.
    if [ ! -f "$POLKIT_RULE_PATH" ]; then
        echo "ℹ️ Polkit rule for password-less mounting is not found."
        echo "This script needs to create a rule at $POLKIT_RULE_PATH."
        echo "This will allow any user in the 'wheel' group to mount drives without a password."
        echo "--- You will be prompted for your password to grant permission. ---"
        
        sudo tee "$POLKIT_RULE_PATH" > /dev/null <<'EOF'
// Allow users in the 'wheel' group to mount internal drives without a password
// This is generally safe for a single-user desktop system.
polkit.addRule(function(action, subject) {
    if (action.id == "org.freedesktop.udisks2.filesystem-mount-system" &&
        subject.isInGroup("wheel")) {
        return polkit.Result.YES;
    }
});
EOF

        if [ $? -ne 0 ]; then
            echo "❌ Failed to create Polkit rule. Aborting."
            return 1
        fi
        echo "✅ Polkit rule created successfully. A reboot is recommended to ensure it takes effect."
    fi

    # Step 2: Proceed with systemd service setup.
    if systemctl --user is-enabled "$SERVICE_NAME" &>/dev/null; then
        echo "✅ Auto-mount service is already enabled."
        return
    fi

    echo "▶️ Creating systemd service file..."
    mkdir -p "$(dirname "$SERVICE_FILE_PATH")"

    cat > "$SERVICE_FILE_PATH" << EOF
[Unit]
Description=Auto-mount removable drives using udisksctl
After=graphical-session.target

[Service]
Type=oneshot
ExecStart=$SERVICE_SCRIPT_PATH

[Install]
WantedBy=default.target
EOF

    echo "▶️ Reloading systemd user daemon..."
    systemctl --user daemon-reload

    echo "▶️ Enabling the service to start on login..."
    systemctl --user enable "$SERVICE_NAME"

    echo "▶️ Starting the service now..."
    systemctl --user start "$SERVICE_NAME"

    echo "✅ Successfully enabled and started the auto-mount service."
}

# Function to disable and stop the systemd service.
disable_service() {
    if ! systemctl --user is-enabled "$SERVICE_NAME" &>/dev/null && ! systemctl --user is-active "$SERVICE_NAME" &>/dev/null; then
        echo "ℹ️ Auto-mount service is not active or enabled."
        return
    fi

    echo "▶️ Stopping the service..."
    systemctl --user stop "$SERVICE_NAME"

    echo "▶️ Disabling the service..."
    systemctl --user disable "$SERVICE_NAME"

    echo "▶️ Removing systemd service file..."
    rm -f "$SERVICE_FILE_PATH"

    # Remove the Polkit rule if it exists
    if [ -f "$POLKIT_RULE_PATH" ]; then
        echo "▶️ Removing Polkit rule... (requires sudo)"
        sudo rm -f "$POLKIT_RULE_PATH"
        echo "✅ Polkit rule removed."
    fi

    echo "▶️ Reloading systemd user daemon..."
    systemctl --user daemon-reload

    echo "❌ Successfully disabled and removed the auto-mount service."
}

#-------------------------------------------------------
# Interactive Menu
#-------------------------------------------------------
main() {
    echo "----------------------------------------"
    echo "  Auto-Mount Service Manager"
    echo "----------------------------------------"
    echo "This script will manage a systemd service and the required"
    echo "Polkit permissions to automatically mount drives at login."
    echo
    echo "Current Status:"
    if systemctl --user is-active --quiet "$SERVICE_NAME"; then
        echo "  - Service is ACTIVE and RUNNING."
    else
        echo "  - Service is INACTIVE."
    fi
    if systemctl --user is-enabled --quiet "$SERVICE_NAME"; then
        echo "  - Service is ENABLED to start on login."
    else
        echo "  - Service is DISABLED."
    fi
    if [ -f "$POLKIT_RULE_PATH" ]; then
        echo "  - Polkit rule EXISTS."
    else
        echo "  - Polkit rule NOT FOUND."
    fi
    echo

    echo "1) Enable"
    echo "2) Disable"
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
            echo "👋 Action cancelled."
            ;;
    esac
}

# Run the main function
main
