#!/bin/bash

#-------------------------------------------------------
# Script to get media player metadata for Hyprlock
#-------------------------------------------------------

# Source helper functions
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$DIR/../../.."
HELPER_SCRIPT="$PROJECT_ROOT/scripts/install_modules/helpers.sh"
source "$HELPER_SCRIPT"

_log INFO "Retrieving media player metadata..."

playerctl metadata --format "[{{ status }}]  {{ trunc(title, 30) }} - {{ artist }}"

if [ $? -eq 0 ]; then
    _log SUCCESS "Media player metadata retrieved successfully."
else
    _log WARN "No media player metadata found or playerctl not running."
fi
