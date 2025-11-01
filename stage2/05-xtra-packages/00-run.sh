#!/bin/bash -e

install -m 644 files/40-local-basic-rules.rules "${ROOTFS_DIR}/etc/polkit-1/rules.d/"

#if [ -f "${ROOTFS_DIR}/etc/update-motd.d/10-uname" ]; then
#    rm "${ROOTFS_DIR}/etc/update-motd.d/10-uname"
#    mkdir "${ROOTFS_DIR}/etc/update-motd-static.d"
#fi

#touch "${ROOTFS_DIR}/etc/update-motd.d/20-update"
#chmod 755 "${ROOTFS_DIR}/etc/update-motd.d/20-update"

#install -m 755 files/10-welcome "${ROOTFS_DIR}/etc/update-motd.d/"
#install -m 755 files/15-system "${ROOTFS_DIR}/etc/update-motd.d/"
#install -m 755 files/20-update "${ROOTFS_DIR}/etc/update-motd-static.d/"

#install -m 644 files/motd-update.timer "${ROOTFS_DIR}/etc/systemd/system/"
#install -m 755 files/motd-update.service "${ROOTFS_DIR}/etc/systemd/system/"

#sed -i -Ee 's/^#?[[:blank:]]*PrintLastLog[[:blank:]]*yes[[:blank:]]*$/PrintLastLog no/' \
#  "${ROOTFS_DIR}/etc/ssh/sshd_config"

#on_chroot << EOF
#systemctl enable motd-update.timer
#run-parts /etc/update-motd-static.d
#EOF

on_chroot << EOF
#apt-mark manual 
#apt-get -y purge 
apt-get -y --purge autoremove
apt-get clean
EOF
