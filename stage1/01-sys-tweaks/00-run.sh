#!/bin/bash

set -euo pipefail

install -v -d "${ROOTFS_DIR}/etc/systemd/system/getty@tty1.service.d"
install -v -m 644 files/noclear.conf "${ROOTFS_DIR}/etc/systemd/system/getty@tty1.service.d/noclear.conf"
install -v -m 644 files/fstab "${ROOTFS_DIR}/etc/fstab"

# FIRST_USER_PASS uses :- default because it may be intentionally unset
# (passwordless user). Without :- the heredoc expansion fails under set -u.
on_chroot << EOF
if ! id -u ${FIRST_USER_NAME} >/dev/null 2>&1; then
	adduser --disabled-password --gecos "" ${FIRST_USER_NAME}
fi

if [ -n "${FIRST_USER_PASS:-}" ]; then
	echo "${FIRST_USER_NAME}:${FIRST_USER_PASS:-}" | chpasswd
fi
echo "root:root" | chpasswd
EOF

# Written directly to ROOTFS_DIR rather than inside on_chroot so the
# filename contains the resolved username, not the literal variable string.
# 0440 is mandatory — sudo refuses to load sudoers.d files with more
# permissive modes (it logs "bad permissions" and ignores the file entirely).
echo "${FIRST_USER_NAME} ALL=(ALL) NOPASSWD: ALL" \
    > "${ROOTFS_DIR}/etc/sudoers.d/010_${FIRST_USER_NAME}-nopasswd"
chmod 0440 "${ROOTFS_DIR}/etc/sudoers.d/010_${FIRST_USER_NAME}-nopasswd"
