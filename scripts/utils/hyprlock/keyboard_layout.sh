#!/bin/bash

# Get the active keymap from hyprctl, focusing on the main keyboard
active_keymap=$(hyprctl -j devices | jq -r '.keyboards[] | select(.main == true) | .active_keymap')

# Default to the first keyboard if no main keyboard is found
if [[ -z "$active_keymap" ]]; then
    active_keymap=$(hyprctl -j devices | jq -r '.keyboards[0].active_keymap')
fi

# Check for known layouts and print a short version
if [[ "$active_keymap" == *"Thai"* ]]; then
    echo "TH"
elif [[ "$active_keymap" == *"English"* ]]; then
    echo "EN"
else
    # Fallback for other languages: take the first two letters and uppercase them
    if [[ -n "$active_keymap" ]]; then
        echo "${active_keymap:0:2}" | tr '[:lower:]' '[:upper:]'
    else
        echo "??"
    fi
fi
