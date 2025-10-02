#!/bin/bash

#-------------------------------------------------------
# Script to toggle and position Pavucontrol
#-------------------------------------------------------

# Source helper functions
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$DIR/../.."
HELPER_SCRIPT="$PROJECT_ROOT/scripts/install_modules/helpers.sh"
source "$HELPER_SCRIPT"

if pgrep -x "pavucontrol-qt" >/dev/null; then
    echo "Pavucontrol is running. Killing it..."
    killall pavucontrol-qt
    _log SUCCESS "Pavucontrol killed."
else
    echo "Pavucontrol is not running. Launching it..."
    pavucontrol-qt &

    local window_address=""
    for i in {1..50}; do
        window_address=$(hyprctl -j clients | jq -r '.[] | select(.class | test("pavucontrol-qt"; "i")) | .address')
        if [ -n "$window_address" ]; then
            echo "Pavucontrol window found at address: $window_address"
            break
        fi
        sleep 0.1 # Wait a bit for the window to appear
    done

    if [ -n "$window_address" ]; then
        echo "Positioning and resizing Pavucontrol window..."
        hyprctl --batch "\
            dispatch setfloating address:$window_address;\
            dispatch pin address:$window_address;\
            dispatch resizewindowpixel exact 36% 55%,address:$window_address;\
            dispatch movewindowpixel exact 63% 43%,address:$window_address" 
        _log SUCCESS "Pavucontrol window positioned and resized."
    else
        _log WARN "Pavucontrol window not found after launch. Skipping positioning."
    fi
fi