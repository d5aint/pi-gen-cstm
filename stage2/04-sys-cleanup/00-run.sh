#!/bin/bash -e

on_chroot << EOF
#apt-mark manual 

apt-get -y purge cloud-init
apt-get -y --purge autoremove
apt-get clean
EOF
