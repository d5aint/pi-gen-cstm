#!/bin/bash

set -euo pipefail

on_chroot << EOF
apt-mark manual lsb-release
apt-get -y purge pastebinit
apt-get -y --purge autoremove
apt-get clean
EOF
