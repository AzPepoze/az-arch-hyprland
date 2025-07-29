#!/bin/bash

# Get player status from playerctl
PLAYER_STATUS=$(playerctl status 2> /dev/null)

# Exit if player is not running or paused
if [[ "$PLAYER_STATUS" != "Playing" && "$PLAYER_STATUS" != "Paused" ]]; then
    echo ""
    exit 0
fi

# Get position and total length
position_sec_float=$(playerctl position)
total_sec_micro=$(playerctl metadata mpris:length)

# Check for valid data
if [[ -z "$position_sec_float" || -z "$total_sec_micro" ]]; then
    echo ""
    exit 0
fi

# Convert microseconds to seconds
total_sec=$(echo "$total_sec_micro / 1000000" | bc)
position_sec=$(echo "$position_sec_float" | cut -d. -f1)

# Avoid division by zero
if (( total_sec == 0 )); then
    echo ""
    exit 0
fi

# Calculate percentage
percent=$(( position_sec * 100 / total_sec ))

# --- Progress Bar Configuration ---
filled_char="━"   # Thicker character for the filled part
unfilled_char="─" # Thinner character for the unfilled part
knob_char="●"
bar_length=24     # Total length of the bar

# Calculate how many characters are filled
filled_length=$(( percent * bar_length / 100 ))

# Build the bar string
bar=""

# 1. Add filled characters
for (( i=0; i < filled_length; i++ )); do
    bar+=$filled_char
done

# 2. Add the knob
bar+=$knob_char

# 3. Add unfilled characters
remaining_length=$(( bar_length - filled_length ))
for (( i=0; i < remaining_length; i++ )); do
    bar+=$unfilled_char
done

echo "$bar"