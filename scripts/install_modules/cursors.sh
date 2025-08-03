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
PROJECT_ROOT="$(cd "$DIR/../.." && pwd)"
HELPER_SCRIPT="$DIR/helpers.sh"

# Source helper functions (MUST be at the top)
source "$HELPER_SCRIPT"

# Source and Destination directories
BUILT_THEMES_DIR="$PROJECT_ROOT/dist/cursors"
USER_ICON_DIR="$HOME/.local/share/icons"
CONFIG_FILE="$PROJECT_ROOT/settings/config.json"

#-------------------------------------------------------
# Main Execution
#-------------------------------------------------------

install_cursors() {

    echo "Starting Cursor Theme Installation..."

    if [ ! -d "$BUILT_THEMES_DIR" ] || [ -z "$(ls -A "$BUILT_THEMES_DIR")" ]; then
        _log ERROR "Built cursor themes not found in '$BUILT_THEMES_DIR'."
        echo "Please run the './build_cursors.sh' script from the project root first."
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
    echo "Select the cursor theme to install:"
    select theme_name in "${themes[@]}"; do
        case "$theme_name" in
            "Exit")
                echo "Exiting without installation."
                return 0
                ;;
            *)
                # Check if the selected option is valid
                if [[ " ${themes[*]} " =~ " ${theme_name} " ]]; then
                    echo "Installing theme: $theme_name"

                    # Ensure destination directory exists
                    mkdir -p "$USER_ICON_DIR"
                    echo "Ensured icon directory exists at '$USER_ICON_DIR'"

                    # Copy the theme files
                    cp -r "$BUILT_THEMES_DIR/$theme_name" "$USER_ICON_DIR/"
                    _log SUCCESS "Copied '$theme_name' to '$USER_ICON_DIR'"

                    # Update config.json
                    jq --arg theme "$theme_name" '.cursor.theme = $theme' "$CONFIG_FILE" > "${CONFIG_FILE}.tmp" && mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
                    _log SUCCESS "Updated cursor theme in config file."

                    break
                else
                    _log ERROR "Invalid option '$REPLY'. Please try again."
                fi
                ;;
        esac
    done
}


