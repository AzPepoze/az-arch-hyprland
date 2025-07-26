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

# Get album art URL from playerctl
ART_URL=$(playerctl -f "{{mpris:artUrl}}" metadata)

if [[ -n "$ART_URL" ]]; then
    # Remove the "file://" prefix
    ART_PATH="${ART_URL/file:\/\//}"
    echo "$ART_PATH"
else
    echo "$DEFAULT_ART"
fi
