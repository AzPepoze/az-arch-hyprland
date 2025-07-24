#!/bin/bash

#-------------------------------------------------------
# Script to zoom active window to fit monitor
#-------------------------------------------------------

# Source helper functions
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$DIR/../.."
HELPER_SCRIPT="$PROJECT_ROOT/scripts/install_modules/helpers.sh"
source "$HELPER_SCRIPT"

_log INFO "Attempting to zoom active window to fit monitor..."

active_window_json=$(hyprctl activewindow -j)
monitors_json=$(hyprctl monitors -j)

window_address=$(echo "$active_window_json" | jq -r '.address')
window_x=$(echo "$active_window_json" | jq '.at[0]')
window_y=$(echo "$active_window_json" | jq '.at[1]')
window_w=$(echo "$active_window_json" | jq '.size[0]')
window_h=$(echo "$active_window_json" | jq '.size[1]')

active_monitor_json=$(echo "$monitors_json" | jq -c ".[] | select(.x <= $window_x and .y <= $window_y and (.x + .width) >= ($window_x + $window_w) and (.y + .height) >= ($window_y + $window_h))" | head -n 1)

monitor_w=$(echo "$active_monitor_json" | jq '.width')
monitor_h=$(echo "$active_monitor_json" | jq '.height')
monitor_x=$(echo "$active_monitor_json" | jq '.x')
monitor_y=$(echo "$active_monitor_json" | jq '.y')

window_ratio=$(echo "scale=10; $window_w / $window_h" | bc)
monitor_ratio=$(echo "scale=10; $monitor_w / $monitor_h" | bc)

if (( $(echo "$window_ratio > $monitor_ratio" | bc -l) )); then
    new_w=$monitor_w
    new_h=$(echo "scale=10; $new_w / $window_ratio" | bc | cut -d'.' -f1)
else
    new_h=$monitor_h
    new_w=$(echo "scale=10; $new_h * $window_ratio" | bc | cut -d'.' -f1)
fi

new_w=${new_w:-$window_w}
new_h=${new_h:-$window_h}

new_x=$(( monitor_x + (monitor_w - new_w) / 2 ))
new_y=$(( monitor_y + (monitor_h - new_h) / 2 ))

hyprctl dispatch resizewindowpixel exact $new_w $new_h,address:$window_address;
hyprctl dispatch centerwindow

_log SUCCESS "Active window zoomed and centered."