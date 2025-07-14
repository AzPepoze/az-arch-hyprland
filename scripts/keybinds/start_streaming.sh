#!/bin/bash

# ------------------------------------------------------
# Hyprland Streaming Mode Script (ON)
# ------------------------------------------------------

# This script uses hyprctl to disable resource-intensive graphical effects
# for a smoother streaming or recording experience.

hyprctl --batch "
    keyword animations:enabled false;
    keyword decoration:drop_shadow false;
    keyword decoration:blur:enabled false;
    keyword general:border_size 1;
    keyword decoration:rounding 0;
    keyword input:touchpad:enabled false;
    keyword input:keyboard:enabled false;
    keyword input:mouse:enabled false"

# Send a notification to confirm that streaming mode is active
notify-send -u low -i video-display "Hyprland" "Streaming Mode ON: Input Disabled"
