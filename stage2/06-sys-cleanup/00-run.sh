#!/bin/bash -e

on_chroot << EOF
apt-mark manual libpcap0.8t64
apt-get -y purge cloud-guest-utils cloud-init lrzsz modemmanager network-manager-l10n \
ppp python3-bs4 python3-cssselect python3-html5lib python3-mdurl python3-pygments \
python3-soupsieve python3-typing-extensions python3-uc-micro python3-webencodings

apt-get -y --purge autoremove
apt-get clean
EOF
