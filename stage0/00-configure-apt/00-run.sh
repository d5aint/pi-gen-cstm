#!/bin/bash

set -euo pipefail

true > "${ROOTFS_DIR}/etc/apt/sources.list"
install -m 644 files/80suggests    "${ROOTFS_DIR}/etc/apt/apt.conf.d/"
install -m 644 files/debian.sources "${ROOTFS_DIR}/etc/apt/sources.list.d/"
install -m 644 files/raspi.sources  "${ROOTFS_DIR}/etc/apt/sources.list.d/"
sed -i "s/RELEASE/${RELEASE}/g" "${ROOTFS_DIR}/etc/apt/sources.list.d/debian.sources"
sed -i "s/RELEASE/${RELEASE}/g" "${ROOTFS_DIR}/etc/apt/sources.list.d/raspi.sources"

# WHY: APT_PROXY and TEMP_REPO are optional pi-gen env vars; :- avoids
# unbound variable errors under set -u when the caller omits them.
if [[ -n "${APT_PROXY:-}" ]]; then
	install -m 644 files/51cache "${ROOTFS_DIR}/etc/apt/apt.conf.d/51cache"
	sed "${ROOTFS_DIR}/etc/apt/apt.conf.d/51cache" -i -e "s|APT_PROXY|${APT_PROXY}|"
else
	rm -f "${ROOTFS_DIR}/etc/apt/apt.conf.d/51cache"
fi

if [[ -n "${TEMP_REPO:-}" ]]; then
	install -m 644 /dev/null "${ROOTFS_DIR}/etc/apt/sources.list.d/00-temp.list"
	echo "$TEMP_REPO" | sed "s/RELEASE/$RELEASE/g" > "${ROOTFS_DIR}/etc/apt/sources.list.d/00-temp.list"
else
	rm -f "${ROOTFS_DIR}/etc/apt/sources.list.d/00-temp.list"
fi

# WHY: raspi.sources references raspberrypi-archive-keyring.gpg; installing
# with the .pgp suffix causes apt to silently skip the RPi Packages index,
# making packages like raspi-config unfindable at stage1.
install -m 644 files/raspberrypi-archive-keyring.pgp \
    "${ROOTFS_DIR}/usr/share/keyrings/raspberrypi-archive-keyring.gpg"

# WHY: backslash-quoted \EOF prevents the outer shell from expanding $ARCH here;
# dpkg --print-architecture runs inside the chroot and returns the chroot arch.
on_chroot <<- \EOF
	ARCH="$(dpkg --print-architecture)"
	if [[ "$ARCH" = "armhf" ]]; then
		dpkg --add-architecture arm64
	elif [[ "$ARCH" = "arm64" ]]; then
		dpkg --add-architecture armhf
	fi
	apt-get update
	apt-get dist-upgrade -y
EOF
