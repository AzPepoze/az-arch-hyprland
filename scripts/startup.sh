#!/bin/bash

#-------------------------------------------------------
# Background Services
#-------------------------------------------------------
# if command -v quickshell &>/dev/null; then
#     quickshell &
# fi

bash $HOME/az-arch/scripts/rclone/sync.sh &

#-------------------------------------------------------
# Startup Programs
#-------------------------------------------------------
sleep 1 && linux-wallpaperengine-gui --minimized &

hyprctl dispatch exec "[workspace 1 silent] youtube-music"
sleep 2

MESSENGER_DESKTOP_FILE=$(grep -l "^Name=Messenger$" ~/.local/share/applications/*.desktop /usr/share/applications/*.desktop 2>/dev/null | head -n 1)

if [ -n "$MESSENGER_DESKTOP_FILE" ]; then
    APP_ID=$(basename "$MESSENGER_DESKTOP_FILE" .desktop)
    hyprctl dispatch exec "[workspace 1 silent] gtk-launch ${APP_ID}"
fi
sleep 2

hyprctl dispatch exec "[workspace 1 silent] flatpak run dev.vencord.Vesktop"

hyprctl dispatch exec "[workspace 4 silent] sh -c 'sleep 10 && wineboot'"
