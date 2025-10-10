#!/bin/bash

# --- Configuration ---
# The script will now automatically detect the user who ran the sudo command.
# You no longer need to set the username manually.

# --- CHOOSE YOUR SESSION ---
# For a standard Hyprland session, use "hyprland.desktop".
# For a UWSM-managed Hyprland session, it's likely "hyprland-uwsm.desktop".
# Verify the correct .desktop file name in /usr/share/wayland-sessions/
AUTOLOGIN_SESSION="hyprland-uwsm.desktop"


# --- Script Logic ---
# Define the path for the autologin configuration file.
AUTOLOGIN_CONF_DIR="/etc/sddm.conf.d"
AUTOLOGIN_CONF_FILE="$AUTOLOGIN_CONF_DIR/autologin.conf"

# --- Functions ---

# Function to display how to use the script
usage() {
    echo "Usage: sudo $0 [enable|disable]"
    echo "  enable  : Enables autologin for the current user ($SUDO_USER)."
    echo "  disable : Disables autologin by removing the configuration file."
    exit 1
}

# Function to enable autologin
enable_autologin() {
    # Check if SUDO_USER is set. If not, the script was likely run directly as root.
    if [ -z "$SUDO_USER" ]; then
        echo "Error: \$SUDO_USER is not set. Please run this script with sudo, not as the root user."
        echo "Example: sudo $0 enable"
        exit 1
    fi

    echo "Enabling SDDM autologin for user: $SUDO_USER"

    # Create the configuration directory if it doesn't exist.
    if [ ! -d "$AUTOLOGIN_CONF_DIR" ]; then
        mkdir -p "$AUTOLOGIN_CONF_DIR"
        echo "Created directory: $AUTOLOGIN_CONF_DIR"
    fi

    # Create the autologin configuration file.
    echo "Creating autologin configuration file: $AUTOLOGIN_CONF_FILE"
    cat > "$AUTOLOGIN_CONF_FILE" << EOF
[Autologin]
User=$SUDO_USER
Session=$AUTOLOGIN_SESSION
EOF

    echo "SDDM autologin has been enabled for user '$SUDO_USER' with session '$AUTOLOGIN_SESSION'."
    echo "Please reboot your system for the changes to take effect."
}

# Function to disable autologin
disable_autologin() {
    echo "Disabling SDDM autologin..."

    if [ -f "$AUTOLOGIN_CONF_FILE" ]; then
        rm -f "$AUTOLOGIN_CONF_FILE"
        echo "Removed autologin configuration file: $AUTOLOGIN_CONF_FILE"
        echo "Autologin has been disabled."
        echo "Please reboot your system for the changes to take effect."
    else
        echo "Autologin configuration file not found. It might already be disabled."
    fi
}


# --- Main Script Execution ---

# Check if the script is run with root privileges.
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root. Please use sudo." >&2
  exit 1
fi

# Check the command-line argument and call the appropriate function.
case "$1" in
    enable)
        enable_autologin
        ;;
    disable)
        disable_autologin
        ;;
    *)
        usage
        ;;
esac

exit 0