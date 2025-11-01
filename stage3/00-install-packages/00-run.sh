#!/bin/bash -e

install -v -m 0755 -o 1000 -g 1000 -d              "${ROOTFS_DIR}/home/${FIRST_USER_NAME}/.config/{i3/scripts,rofi}"
install -m 664 -o 1000 -g 1000 files/config        "${ROOTFS_DIR}/home/${FIRST_USER_NAME}/.config/i3/"
install -m 644 -o 1000 -g 1000 files/wallpaper.jpg "${ROOTFS_DIR}/home/${FIRST_USER_NAME}/.config/i3/"
install -m 755 -o 1000 -g 1000 files/power-menu.sh "${ROOTFS_DIR}/home/${FIRST_USER_NAME}/.config/i3/scripts/"
install -m 664 -o 1000 -g 1000 files/config.rasi   "${ROOTFS_DIR}/home/${FIRST_USER_NAME}/.config/rofi/"

on_chroot << EOF
xdg-user-dirs-update
EOF
