#!/bin/bash

set -euo pipefail

install -m 644 files/40-local-basic-rules.rules "${ROOTFS_DIR}/etc/polkit-1/rules.d/"

on_chroot << EOF
#apt-mark manual
#apt-get -y purge
apt-get -y --purge autoremove
apt-get clean
EOF
