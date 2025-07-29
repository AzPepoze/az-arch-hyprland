#!/bin/bash

# Get player status from playerctl
PLAYER_STATUS=$(playerctl status 2> /dev/null)

# Exit if player is not running
if [[ "$PLAYER_STATUS" != "Playing" && "$PLAYER_STATUS" != "Paused" ]]; then
    echo ""
    exit 0
fi

# Get position and total length
position_sec=$(playerctl position | cut -d. -f1)
total_sec_micro=$(playerctl metadata mpris:length)

# Check for valid data
if [[ -z "$position_sec" || -z "$total_sec_micro" ]]; then
    echo ""
    exit 0
fi

total_sec=$(echo "$total_sec_micro / 1000000" | bc)

# Format time to MM:SS
pos_formatted=$(printf "%02d:%02d" $((position_sec / 60)) $((position_sec % 60)))
len_formatted=$(printf "%02d:%02d" $((total_sec / 60)) $((total_sec % 60)))

echo "$pos_formatted / $len_formatted"