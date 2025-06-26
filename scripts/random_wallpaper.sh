#!/bin/bash

# Source the configuration file

while true; do
  source "$(dirname "$0")/../configs/random_wallpaper.conf"

  # Kill any existing wallpaper engine process
  pkill -f "linux-wallpaperengine"

  # Get a random wallpaper from the directory
  WALLPAPER=$(find "$WALLPAPER_DIR" -mindepth 1 -maxdepth 1 -type d | shuf -n 1)

  # Set the wallpaper in the background
  if [ -n "$WALLPAPER" ]; then
    linux-wallpaperengine -r "$SCREEN" -f "$FPS" -s "$(basename "$WALLPAPER")" &
  fi

  # Wait for the specified interval
  sleep "$INTERVAL"
done