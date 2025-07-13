#!/bin/sh

#
# ------------------------------------------------------
# Script to switch keyboard layout and send notification
# ------------------------------------------------------
#

# รับชื่อ Keyboard ทั้งหมด
KEYBOARDS=$(hyprctl devices -j | jq -r '.keyboards[] | .name')

# สลับ Layout ของแต่ละ Keyboard
for KBD in $KEYBOARDS; do
    hyprctl switchxkblayout "$KBD" next
done

# แสดง Notification
CURRENT_LAYOUT=$(hyprctl devices -j | jq -r '.keyboards[0] | .active_keymap')
notify-send -h string:x-canonical-private-synchronous:hypr-layout -u low "Keyboard Layout" "Changed to $CURRENT_LAYOUT"
