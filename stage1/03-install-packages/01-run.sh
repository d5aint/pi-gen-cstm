#!/bin/bash

set -euo pipefail

on_chroot << EOF
apt-mark manual lsb-release
apt-get -y purge alsa-topology-conf alsa-ucm-conf pastebinit \
python3-distro

apt-get -y --purge autoremove
apt-get clean
EOF
