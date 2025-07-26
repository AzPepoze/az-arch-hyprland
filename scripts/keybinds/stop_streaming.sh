#!/bin/bash

#-------------------------------------------------------
# Hyprland Streaming Mode Script (OFF)
#-------------------------------------------------------

# Source helper functions
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$DIR/../.."
HELPER_SCRIPT="$PROJECT_ROOT/scripts/install_modules/helpers.sh"
source "$HELPER_SCRIPT"

echo "Disabling Hyprland Streaming Mode..."

hyprctl --batch "\
    keyword animations:enabled true;\
    keyword decoration:drop_shadow true;\
    keyword decoration:blur:enabled true;\
    keyword general:border_size 2;\
    keyword decoration:rounding 10;\
    keyword input:touchpad:enabled true;\
    keyword input:keyboard:enabled true;\
    keyword input:mouse:enabled true"

# Send a notification to confirm that streaming mode is off
notify-send -u low -i video-display "Hyprland" "Streaming Mode OFF: Input Enabled"
_log SUCCESS "Hyprland Streaming Mode OFF. Input devices enabled."