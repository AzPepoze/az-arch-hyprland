#!/bin/bash

#-------------------------------------------------------
# Background Services
#-------------------------------------------------------
# Start the rclone sync script
bash $HOME/arch-setup/scripts/rclone/sync.sh &

#-------------------------------------------------------
# Startup Programs
#-------------------------------------------------------
# System & Background Services
hyprpm reload && hyprpm update
hyprpm enable Hyprspace
sleep 1 && linux-wallpaperengine-gui --minimized &

# Autostart Applications (via hyprctl)
hyprctl dispatch exec "[workspace 1 silent] youtube-music"
hyprctl dispatch exec "[workspace 1 silent] flatpak run dev.vencord.Vesktop"

# Find and launch Messenger by its desktop file name
MESSENGER_DESKTOP_FILE=$(grep -l "^Name=Messenger$" ~/.local/share/applications/*.desktop /usr/share/applications/*.desktop 2>/dev/null | head -n 1)

if [ -n "$MESSENGER_DESKTOP_FILE" ]; then
     APP_ID=$(basename "$MESSENGER_DESKTOP_FILE" .desktop)
     hyprctl dispatch exec "[workspace 1 silent] gtk-launch ${APP_ID}"
fi

hyprctl dispatch exec "[workspace 4 silent] sh -c 'sleep 10 && wineboot'"
