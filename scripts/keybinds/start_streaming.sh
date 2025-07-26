#!/bin/bash

#-------------------------------------------------------
# Hyprland Streaming Mode Script (ON)
#-------------------------------------------------------

# Source helper functions
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$DIR/../.."
HELPER_SCRIPT="$PROJECT_ROOT/scripts/install_modules/helpers.sh"
source "$HELPER_SCRIPT"

echo "Enabling Hyprland Streaming Mode..."

hyprctl --batch "\
    keyword animations:enabled false;\
    keyword decoration:drop_shadow false;\
    keyword decoration:blur:enabled false;\
    keyword general:border_size 1;\
    keyword decoration:rounding 0;\
    keyword input:touchpad:enabled false;\
    keyword input:keyboard:enabled false;\
    keyword input:mouse:enabled false"

# Send a notification to confirm that streaming mode is active
notify-send -u low -i video-display "Hyprland" "Streaming Mode ON: Input Disabled"
_log SUCCESS "Hyprland Streaming Mode ON. Input devices disabled."