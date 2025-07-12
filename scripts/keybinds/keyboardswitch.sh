#!/bin/bash

#-------------------------------------------------------
# Group: Utilities
# Subgroup: Keyboard Layout
#-------------------------------------------------------

# Configuration
KEYBOARD_DEVICE_NAME="at-translated-keyboard"

# Get current keyboard layout
current_layout=$(hyprctl devices -j | jq -r '.keyboards[] | select(.name == "$KEYBOARD_DEVICE_NAME") | .active_keymap')

# Define layouts (adjust as needed)
layouts=("us" "th") # Example: US and Thai layouts

# Find the index of the current layout
current_index=-1
for i in "${!layouts[@]}"; do
    if [[ "${layouts[$i]}" == "$current_layout" ]]; then
        current_index=$i
        break
    fi
done

# Calculate the next layout index
next_index=$(((current_index + 1) % ${#layouts[@]}))
next_layout=${layouts[$next_index]}

# Set the new keyboard layout
hyprctl keyword device:$KEYBOARD_DEVICE_NAME:keymap "$next_layout"

# Optional: Send a notification to show the new layout
notify-send "Keyboard Layout" "Switched to: $(echo "$next_layout" | tr '[:lower:]' '[:upper:]')" -t 1500
