#!/bin/bash

# Check if pavucontrol process exists
if pgrep -x "pavucontrol" > /dev/null; then
    # If it exists, kill it
    killall pavucontrol
else
    # If it does not exist, launch it in the background
    pavucontrol &

    # Wait for pavucontrol to open and get its address
    for i in {1..50}; do # 5 seconds timeout
        window_address=$(hyprctl -j clients | jq -r '.[] | select(.class | test("pavucontrol"; "i")) | .address')
        if [ -n "$window_address" ]; then
            break
        fi
    done

    # If window is found, then manipulate it
    if [ -n "$window_address" ]; then
        hyprctl --batch "\
            dispatch setfloating address:$window_address;\
            dispatch pin address:$window_address;\
            dispatch resizewindowpixel exact 700 600,address:$window_address;\
            dispatch movewindowpixel exact 1210 470,address:$window_address"
    fi
fi