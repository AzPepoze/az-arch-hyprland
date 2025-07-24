#!/bin/bash

#==============================================================================
# CURSOR INSTALL SCRIPT
#------------------------------------------------------------------------------
# This script installs pre-built cursor themes located in the 'dist/cursors'
# directory. It should be run by the end-user as part of the main installer.
#
# It does NOT build or convert any files. Run 'build_cursors.sh' first to
# generate the necessary theme files.
#==============================================================================

#-------------------------------------------------------
# Variables
#-------------------------------------------------------
# Get the directory of the script to locate the project root
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$DIR/../.."
HELPER_SCRIPT="$DIR/helpers.sh"

# Source helper functions (MUST be at the top)
source "$HELPER_SCRIPT"

# Source and Destination directories
BUILT_THEMES_DIR="$PROJECT_ROOT/dist/cursors"
USER_ICON_DIR="$HOME/.local/share/icons"

#-------------------------------------------------------
# Main Execution
#-------------------------------------------------------

install_cursors() {

_log INFO "Starting Cursor Theme Installation..."

if [ ! -d "$BUILT_THEMES_DIR" ] || [ -z "$(ls -A "$BUILT_THEMES_DIR")" ]; then
    _log ERROR "Built cursor themes not found in '$BUILT_THEMES_DIR'."
    _log INFO "Please run the './build_cursors.sh' script from the project root first."
    return 1 # Use return instead of exit for functions called by main script
fi

# Create a list of available themes from the directory names
mapfile -t themes < <(find "$BUILT_THEMES_DIR" -maxdepth 1 -mindepth 1 -type d -exec basename {} \;)
if [ ${#themes[@]} -eq 0 ]; then
    _log ERROR "No themes found in '$BUILT_THEMES_DIR'."
    return 1
fi

themes+=("Exit")

# Display the menu
_log INFO "Select the cursor theme to install:"
select theme_name in "${themes[@]}"; do
    case "$theme_name" in
        "Exit")
            _log INFO "Exiting without installation."
            return 0
            ;;
        *)
            # Check if the selected option is valid
            if [[ " ${themes[*]} " =~ " ${theme_name} " ]]; then
                _log INFO "Installing theme: $theme_name"

                # Ensure destination directory exists
                mkdir -p "$USER_ICON_DIR"
                _log INFO "Ensured icon directory exists at '$USER_ICON_DIR'"

                # Copy the theme files
                cp -r "$BUILT_THEMES_DIR/$theme_name" "$USER_ICON_DIR/"
                _log SUCCESS "Copied '$theme_name' to '$USER_ICON_DIR'"

                # Apply the theme for GTK applications
                if command -v gsettings &> /dev/null; then
                    gsettings set org.gnome.desktop.interface cursor-theme "$theme_name"
                    _log SUCCESS "Set GTK cursor theme to '$theme_name'."
                else
                    _log WARN "'gsettings' command not found. Cannot set GTK cursor theme automatically."
                fi

                # Apply the theme for Hyprland
                if command -v hyprctl &> /dev/null; then
                    hyprctl setcursor "$theme_name" 24
                    _log SUCCESS "Set Hyprland cursor theme to '$theme_name'."
                else
                    _log WARN "'hyprctl' command not found. Cannot set Hyprland cursor theme automatically."
                    _log INFO "To apply in Hyprland, add the following to your configuration (e.g., in custom/env.conf):"
                    echo # Newline for readability
                    echo "  #----------------- Cursor Theme -----------------##"
                    echo "  exec-once = hyprctl setcursor $theme_name 24"
                    echo "  env = HYPRCURSOR_THEME,$theme_name"
                    echo "  env = HYPRCURSOR_SIZE,24"
                    echo "  #----------------------------------------------##"
                    echo # Newline for readability
                fi
                _log INFO "You may need to log out and log back in for changes to take full effect."

                _log SUCCESS "Installation for '$theme_name' complete!"
                break
            else
                _log ERROR "Invalid option '$REPLY'. Please try again."
            fi
            ;;
    esac
done
}