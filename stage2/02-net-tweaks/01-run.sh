#!/bin/bash -e

# Newer versions of raspberrypi-sys-mods set rfkill.default_state=0 to prevent
# radiating on 5GHz bands until the WLAN regulatory domain is set.
# Unfortunately, this also blocks bluetooth, so we whitelist the known
# on-board BT adapters here.

mkdir -p "${ROOTFS_DIR}/var/lib/systemd/rfkill/"
#           5                 miniuart 4      miniuart Zero   miniuart other  other
for addr in 107d50c000.serial 3f215040.serial 20215040.serial fe215040.serial soc; do
	echo 0 > "${ROOTFS_DIR}/var/lib/systemd/rfkill/platform-${addr}:bluetooth"
done

if [ -v WPA_COUNTRY ]; then
	on_chroot <<- EOF
		SUDO_USER="${FIRST_USER_NAME}" raspi-config nonint do_wifi_country "${WPA_COUNTRY}"
	EOF
elif [ -d "${ROOTFS_DIR}/var/lib/NetworkManager" ]; then
	# NetworkManager unblocks all WLAN devices by default. Prevent that:
	cat > "${ROOTFS_DIR}/var/lib/NetworkManager/NetworkManager.state" <<- EOF
		[main]
		WirelessEnabled=false
	EOF
fi


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


#install -v -m 644 files/custom.toml "${ROOTFS_DIR}/boot/firmware/"
#FIRSTUSERPASS=`echo "$FIRST_USER_PASS" | openssl passwd -5 -stdin`

#sed -i -e "s|TARGET_HOSTNAME|${TARGET_HOSTNAME}|g" \
#  -e "s|FIRST_USER_NAME|${FIRST_USER_NAME}|" \
#  -e "s|FIRST_USER_PASS|${FIRSTUSERPASS}|" \
#  -e "s|PUBKEY_SSH_FIRST_USER|${PUBKEY_SSH_FIRST_USER}|" \
#  -e "s|WPA_COUNTRY|${WPA_COUNTRY}|" \
#  -e "s|KEYBOARD_KEYMAP|${KEYBOARD_KEYMAP}|" \
#  -e "s|TIMEZONE_DEFAULT|${TIMEZONE_DEFAULT}|" "${ROOTFS_DIR}/boot/firmware/custom.toml"
