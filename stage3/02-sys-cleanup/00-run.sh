#!/bin/bash

set -euo pipefail

on_chroot << EOF
#apt-mark manual 

apt-get -y purge modemmanager network-manager-l10n ppp python3-bs4 \
python3-cssselect python3-html5lib python3-mdurl python3-pygments \
python3-soupsieve python3-typing-extensions python3-uc-micro \
python3-webencodings vim-common vim-tiny

apt-get -y --purge autoremove
apt-get clean
EOF
