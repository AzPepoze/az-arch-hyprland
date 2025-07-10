#!/bin/bash

if pgrep -x "pavucontrol" >/dev/null; then
    killall pavucontrol
else
    pavucontrol &

    for i in {1..50}; do
        window_address=$(hyprctl -j clients | jq -r '.[] | select(.class | test("pavucontrol"; "i")) | .address')
        if [ -n "$window_address" ]; then
            break
        fi
    done

    if [ -n "$window_address" ]; then
        hyprctl --batch "\
            dispatch setfloating address:$window_address;\
            dispatch pin address:$window_address;\
            dispatch resizewindowpixel exact 700 600,address:$window_address;\
            dispatch movewindowpixel exact 1210 470,address:$window_address"
    fi
fi
