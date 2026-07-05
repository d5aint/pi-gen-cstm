#!/bin/bash

set -euo pipefail

install -m 664 -o 1000 -g 1000 files/fonts-firacode_6.2-3_all.deb "${ROOTFS_DIR}/tmp/fonts-firacode_6.2-3_all.deb"
on_chroot << EOF
    # WHY: -y flag required for non-interactive build; without it apt prompts and hangs.
    apt install -y /tmp/fonts-firacode_6.2-3_all.deb
EOF

# WHY: Brace expansion requires unquoted words; use a base variable so the
# per-directory paths are still quoted individually, preventing word-splitting
# if ROOTFS_DIR or FIRST_USER_NAME ever contains spaces.
base="${ROOTFS_DIR}/home/${FIRST_USER_NAME}/.config"
mkdir -p \
  "${base}/autostart" \
  "${base}/i3/scripts" \
  "${base}/i3status" \
  "${base}/lxterminal" \
  "${base}/picom" \
  "${base}/rofi"
chown -R 1000:1000 "${ROOTFS_DIR}/home/${FIRST_USER_NAME}/.config"

install -m 664 -o 1000 -g 1000 files/config.rasi     "${base}/rofi/config.rasi"
install -m 664 -o 1000 -g 1000 files/i3_config       "${base}/i3/config"
install -m 644 -o 1000 -g 1000 files/i3status_config "${base}/i3status/config"
install -m 664 -o 1000 -g 1000 files/lxterminal.conf "${base}/lxterminal/lxterminal.conf"
install -m 664 -o 1000 -g 1000 files/picom.conf      "${base}/picom/picom.conf"
install -m 664 -o 1000 -g 1000 files/picom.desktop   "${base}/autostart/picom.desktop"
install -m 755 -o 1000 -g 1000 files/power-menu.sh   "${base}/i3/scripts/power-menu.sh"
install -m 644 -o 1000 -g 1000 files/wallpaper.jpg   "${base}/i3/wallpaper.jpg"

on_chroot << EOF
    update-mime-database /usr/share/mime
    SUDO_USER="${FIRST_USER_NAME}" xdg-user-dirs-update
    SUDO_USER="${FIRST_USER_NAME}" raspi-config nonint do_boot_behaviour B2

    apt-mark manual gnome-themes-extra-data
    #apt-get -y purge
    apt-get -y --purge autoremove
    apt-get clean
EOF


# WHY: 'EOF' (single-quoted) prevents the build shell from expanding $DISPLAY
# and $(tty) at image-build time. Without it, $DISPLAY expands to the build
# host's display (usually empty), so the if-condition is always true and
# startx runs unconditionally on every login — including non-tty1 logins.
cat >> "${ROOTFS_DIR}/home/${FIRST_USER_NAME}/.profile" <<- 'EOF'

# Start i3 on login
if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
    startx
fi
EOF
chown 1000:1000 "${ROOTFS_DIR}/home/${FIRST_USER_NAME}/.profile"
