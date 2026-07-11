#!/bin/bash

set -euo pipefail

install -v -d "${ROOTFS_DIR}/etc/systemd/system/getty@tty1.service.d"
install -v -m 644 files/noclear.conf "${ROOTFS_DIR}/etc/systemd/system/getty@tty1.service.d/noclear.conf"

install -v -m 644 files/fstab "${ROOTFS_DIR}/etc/fstab"

if [[ -e "${ROOTFS_DIR}/etc/default/zramswap" ]]; then
    sed -i -e 's/^ALGO=lz4/ALGO=zstd/' -e 's/^PERCENT=50/PERCENT=10/' "${ROOTFS_DIR}/etc/default/zramswap"
fi

sed -i -e 's/^#Storage=auto/Storage=volatile/' -e 's/^#SystemMaxUse=.*/SystemMaxUse=32M/' \
  -e 's/^#RuntimeMaxUse=.*/RuntimeMaxUse=32M/' "${ROOTFS_DIR}/etc/systemd/journald.conf"

on_chroot << EOF
if ! id -u "${FIRST_USER_NAME}" >/dev/null 2>&1; then
	adduser --disabled-login --gecos "" "${FIRST_USER_NAME}"
fi

if [[ -n "${FIRST_USER_PASS:-}" ]]; then
	echo "${FIRST_USER_NAME}:${FIRST_USER_PASS:-}" | chpasswd
	usermod -s /bin/bash "${FIRST_USER_NAME}"
fi
echo "root:root" | chpasswd
EOF
