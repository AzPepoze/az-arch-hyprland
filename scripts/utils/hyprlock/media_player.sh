#!/bin/bash

#-------------------------------------------------------
# Script to get media player metadata for Hyprlock
#-------------------------------------------------------

# Source helper functions
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$DIR/../../.."
HELPER_SCRIPT="$PROJECT_ROOT/scripts/install_modules/helpers.sh"
source "$HELPER_SCRIPT"

playerctl metadata --format "[{{ status }}]  {{ trunc(title, 30) }} - {{ artist }}"
