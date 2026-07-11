#!/bin/bash -e

IMG_FILE="${STAGE_WORK_DIR}/${IMG_FILENAME}${IMG_SUFFIX}.img"

IMGID="$(dd if="${IMG_FILE}" skip=440 bs=1 count=4 2>/dev/null | xxd -e | cut -f 2 -d' ')"

BOOT_PARTUUID="${IMGID}-01"
ROOT_PARTUUID="${IMGID}-05"
VAR_PARTUUID="${IMGID}-06"
VARLOG_PARTUUID="${IMGID}-07"
VARTMP_PARTUUID="${IMGID}-08"
HOME_PARTUUID="${IMGID}-09"

sed -i "s/BOOTDEV/PARTUUID=${BOOT_PARTUUID}/"     "${ROOTFS_DIR}/etc/fstab"
sed -i "s/ROOTDEV/PARTUUID=${ROOT_PARTUUID}/"     "${ROOTFS_DIR}/etc/fstab"
sed -i "s/VARDEV/PARTUUID=${VAR_PARTUUID}/"       "${ROOTFS_DIR}/etc/fstab"
sed -i "s/VARLOGDEV/PARTUUID=${VARLOG_PARTUUID}/" "${ROOTFS_DIR}/etc/fstab"
sed -i "s/VARTMPDEV/PARTUUID=${VARTMP_PARTUUID}/" "${ROOTFS_DIR}/etc/fstab"
sed -i "s/HOMEDEV/PARTUUID=${HOME_PARTUUID}/"     "${ROOTFS_DIR}/etc/fstab"

# Update the kernel cmdline to point to the root logical partition (p5)
sed -i "s/ROOTDEV/PARTUUID=${ROOT_PARTUUID}/" "${ROOTFS_DIR}/boot/firmware/cmdline.txt"
