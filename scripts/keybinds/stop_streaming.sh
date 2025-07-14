#!/bin/bash

# ------------------------------------------------------
# Hyprland Streaming Mode Script (OFF)
# ------------------------------------------------------

# This script restores the default graphical settings.
# You can change the values below to match your personal preference.

hyprctl --batch "\
    keyword animations:enabled true;\
    keyword decoration:drop_shadow true;\
    keyword decoration:blur:enabled true;\
    keyword general:border_size 2;\
    keyword decoration:rounding 10;\
    keyword input:touchpad:enabled true;\
    keyword input:keyboard:enabled true;\
    keyword input:mouse:enabled true"

# Send a notification to confirm that streaming mode is off
notify-send -u low -i video-display "Hyprland" "Streaming Mode OFF: Input Enabled"

