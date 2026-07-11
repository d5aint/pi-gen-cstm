#!/bin/bash

set -euo pipefail

# A rofi-based power menu.
# Use with:
# rofi -show p -modi p:~/.config/i3/scripts/power-menu.sh

chosen=$(printf "  Power Off\n  Restart\n  Logout\n  Lock Screen" | rofi -dmenu -i -p "Power Menu")

case "$chosen" in
    "  Power Off") systemctl poweroff ;;
    "  Restart") systemctl reboot ;;
    "  Logout") i3-msg exit ;;
    "  Lock Screen") i3lock -c 000000 ;;
    *) exit 1 ;;
esac

