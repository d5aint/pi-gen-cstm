#!/bin/bash -e

on_chroot << EOF
apt-mark manual lsb-release
apt-get -y purge apparmor pastebinit python3-distro
apt-get -y --purge autoremove
apt-get clean
EOF
