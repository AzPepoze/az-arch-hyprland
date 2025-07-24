#!/bin/bash

#-------------------------------------------------------
# Script to get album art URL for Hyprlock
#-------------------------------------------------------

# Source helper functions
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$DIR/../../.."
HELPER_SCRIPT="$PROJECT_ROOT/scripts/install_modules/helpers.sh"
source "$HELPER_SCRIPT"

# Path to a default image if no music is playing or no art is found
DEFAULT_ART="/path/to/your/default/image.png" # Consider making this a configurable path

_log INFO "Attempting to retrieve album art URL..."

# Get album art URL from playerctl
ART_URL=$(playerctl -f "{{mpris:artUrl}}" metadata)

if [[ -n "$ART_URL" ]]; then
    # Remove the "file://" prefix
    ART_PATH="${ART_URL/file:\/\//}"
    _log INFO "Album art URL found: $ART_PATH"
    echo "$ART_PATH"
else
    _log INFO "No album art URL found. Using default art: $DEFAULT_ART"
    echo "$DEFAULT_ART"
fi
