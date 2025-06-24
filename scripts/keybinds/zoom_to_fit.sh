#!/bin/sh

# Get active window and monitor info in JSON format
active_window_json=$(hyprctl activewindow -j)
monitors_json=$(hyprctl monitors -j)

# Extract info for the active window
window_address=$(echo "$active_window_json" | jq -r '.address')
window_x=$(echo "$active_window_json" | jq '.at[0]')
window_y=$(echo "$active_window_json" | jq '.at[1]')
window_w=$(echo "$active_window_json" | jq '.size[0]')
window_h=$(echo "$active_window_json" | jq '.size[1]')

# Find the active monitor based on window position
active_monitor_json=$(echo "$monitors_json" | jq -c ".[] | select(.x <= $window_x and .y <= $window_y and (.x + .width) >= ($window_x + $window_w) and (.y + .height) >= ($window_y + $window_h))" | head -n 1)

# Extract active monitor's dimensions
monitor_w=$(echo "$active_monitor_json" | jq '.width')
monitor_h=$(echo "$active_monitor_json" | jq '.height')
monitor_x=$(echo "$active_monitor_json" | jq '.x')
monitor_y=$(echo "$active_monitor_json" | jq '.y')

# Calculate aspect ratios with high precision
window_ratio=$(echo "scale=10; $window_w / $window_h" | bc)
monitor_ratio=$(echo "scale=10; $monitor_w / $monitor_h" | bc)

# Calculate the new size to fit the screen while preserving aspect ratio
# The result from bc is now piped to 'cut' to remove the decimal part
if (( $(echo "$window_ratio > $monitor_ratio" | bc -l) )); then
    # Window is wider than monitor ratio (fit to width)
    new_w=$monitor_w
    new_h=$(echo "scale=10; $new_w / $window_ratio" | bc | cut -d'.' -f1)
else
    # Window is taller or same as monitor ratio (fit to height)
    new_h=$monitor_h
    new_w=$(echo "scale=10; $new_h * $window_ratio" | bc | cut -d'.' -f1)
fi

# Fallback in case new_w or new_h is empty
new_w=${new_w:-$window_w}
new_h=${new_h:-$window_h}


# Calculate the new position to center the window using integer arithmetic
new_x=$(( monitor_x + (monitor_w - new_w) / 2 ))
new_y=$(( monitor_y + (monitor_h - new_h) / 2 ))

# Execute resize and move commands in a single batch for smooth transition
hyprctl dispatch resizewindowpixel exact $new_w $new_h,address:$window_address;
hyprctl dispatch centerwindow