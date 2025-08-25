#!/bin/bash -e

on_chroot << EOF
#apt-mark manual 
apt-get -y purge dmidecode
apt-get -y --purge autoremove
apt-get clean
EOF
