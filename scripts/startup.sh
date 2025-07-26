#!/bin/bash

#-------------------------------------------------------
# Background Services
#-------------------------------------------------------
# Source helper functions
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$DIR/../.."
HELPER_SCRIPT="$PROJECT_ROOT/scripts/install_modules/helpers.sh"
source "$HELPER_SCRIPT"

# if command -v quickshell &>/dev/null; then
#     quickshell &
# fi

echo "Starting rclone sync in background..."
bash $HOME/az-arch/scripts/rclone/sync.sh &
_log SUCCESS "rclone sync started."

#-------------------------------------------------------
# Startup Programs
#-------------------------------------------------------
echo "Starting Linux Wallpaper Engine GUI..."
sleep 1 && linux-wallpaperengine-gui --minimized &
_log SUCCESS "Linux Wallpaper Engine GUI started."

echo "Starting YouTube Music..."
hyprctl dispatch exec "[workspace 1 silent] youtube-music"
sleep 2
_log SUCCESS "YouTube Music started."

echo "Starting Messenger..."
MESSENGER_DESKTOP_FILE=$(grep -l "^Name=Messenger$" ~/.local/share/applications/*.desktop /usr/share/applications/*.desktop 2>/dev/null | head -n 1)

if [ -n "$MESSENGER_DESKTOP_FILE" ]; then
    APP_ID=$(basename "$MESSENGER_DESKTOP_FILE" .desktop)
    hyprctl dispatch exec "[workspace 1 silent] gtk-launch ${APP_ID}"
    _log SUCCESS "Messenger started."
else
    _log WARN "Messenger desktop file not found. Skipping Messenger launch."
fi
sleep 2

echo "Starting Vesktop..."
hyprctl dispatch exec "[workspace 1 silent] flatpak run dev.vencord.Vesktop"
_log SUCCESS "Vesktop started."

echo "Starting Wineboot..."
hyprctl dispatch exec "[workspace 4 silent] sh -c 'sleep 10 && wineboot'"
_log SUCCESS "Wineboot command dispatched."