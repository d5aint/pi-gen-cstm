#!/bin/bash -e

install -m 664 -o 1000 -g 1000 files/fonts-firacode_6.2-3_all.deb "${ROOTFS_DIR}/tmp/fonts-firacode_6.2-3_all.deb"
on_chroot << EOF
    apt install /tmp/fonts-firacode_6.2-3_all.deb
EOF

mkdir -p ${ROOTFS_DIR}/home/${FIRST_USER_NAME}/.config/{autostart,i3/scripts,i3status,lxterminal,picom,rofi}
chown -R 1000:1000 "${ROOTFS_DIR}"/home/"${FIRST_USER_NAME}"/.config

install -m 664 -o 1000 -g 1000 files/config.rasi     "${ROOTFS_DIR}/home/${FIRST_USER_NAME}/.config/rofi/config.rasi"
install -m 664 -o 1000 -g 1000 files/i3_config       "${ROOTFS_DIR}/home/${FIRST_USER_NAME}/.config/i3/config"
install -m 644 -o 1000 -g 1000 files/i3status_config "${ROOTFS_DIR}/home/${FIRST_USER_NAME}/.config/i3status/config"
install -m 664 -o 1000 -g 1000 files/lxterminal.conf "${ROOTFS_DIR}/home/${FIRST_USER_NAME}/.config/lxterminal/lxterminal.conf"
install -m 664 -o 1000 -g 1000 files/picom.conf      "${ROOTFS_DIR}/home/${FIRST_USER_NAME}/.config/picom/picom.conf"
install -m 664 -o 1000 -g 1000 files/picom.desktop   "${ROOTFS_DIR}/home/${FIRST_USER_NAME}/.config/autostart/picom.desktop"
install -m 755 -o 1000 -g 1000 files/power-menu.sh   "${ROOTFS_DIR}/home/${FIRST_USER_NAME}/.config/i3/scripts/power-menu.sh"
install -m 644 -o 1000 -g 1000 files/wallpaper.jpg   "${ROOTFS_DIR}/home/${FIRST_USER_NAME}/.config/i3/wallpaper.jpg"

on_chroot << EOF
    update-mime-database /usr/share/mime
    SUDO_USER="${FIRST_USER_NAME}" xdg-user-dirs-update
    SUDO_USER="${FIRST_USER_NAME}" raspi-config nonint do_boot_behaviour B2

    apt-mark manual gnome-themes-extra-data
    #apt-get -y purge 
    apt-get -y --purge autoremove
    apt-get clean
EOF


cat >> "${ROOTFS_DIR}/home/${FIRST_USER_NAME}/.profile" <<- EOF

# Start i3 on login
if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
    startx
fi
EOF
chown 1000:1000 "${ROOTFS_DIR}"/home/"${FIRST_USER_NAME}"/.profile
