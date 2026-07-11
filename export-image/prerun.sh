#!/bin/bash -e

IMG_FILE="${STAGE_WORK_DIR}/${IMG_FILENAME}${IMG_SUFFIX}.img"

unmount_image "${IMG_FILE}"
rm -f "${IMG_FILE}"
rm -rf "${ROOTFS_DIR}"
mkdir -p "${ROOTFS_DIR}"

# ── Partition sizes ────────────────────────────────────────────────────────────
# All sizes and starts are aligned to ALIGN bytes to avoid performance penalties
# from partitions that straddle erase-block boundaries on SD cards.
ALIGN="$((8 * 1024 * 1024))"

BOOT_SIZE="$((512  * 1024 * 1024))"
HOME_SIZE="$((1024 * 1024 * 1024))"

# Configurable via pi-gen config (or environment). Defaults fit a 16 GB SD card.
# For NVMe builds override in config, e.g.:
#   BUILD_VAR_SIZE=$((16 * 1024 * 1024 * 1024))
#   BUILD_VARLOG_SIZE=$((4  * 1024 * 1024 * 1024))
#   BUILD_VARTMP_SIZE=$((1  * 1024 * 1024 * 1024))
VAR_SIZE="${BUILD_VAR_SIZE:-$((4   * 1024 * 1024 * 1024))}"
VARLOG_SIZE="${BUILD_VARLOG_SIZE:-$((1 * 1024 * 1024 * 1024))}"
VARTMP_SIZE="${BUILD_VARTMP_SIZE:-$((256 * 1024 * 1024))}"

# Root size: measure the built rootfs excluding everything that gets its own
# partition, so ROOT_PART_SIZE reflects only what actually lands on /.
ROOT_SIZE=$(du -x --apparent-size -s "${EXPORT_ROOTFS_DIR}" \
    --exclude boot/firmware \
    --exclude home \
    --exclude tmp \
    --exclude var \
    --exclude var/cache/apt/archives \
    --block-size=1 | cut -f 1)
ROOT_MARGIN="$(echo "($ROOT_SIZE * 0.2 + 200 * 1024 * 1024) / 1" | bc)"

align_up() { echo "$(( ($1 + ALIGN - 1) / ALIGN * ALIGN ))"; }

BOOT_PART_SIZE=$(align_up "$BOOT_SIZE")
ROOT_PART_SIZE=$(align_up "$(( ROOT_SIZE + ROOT_MARGIN ))")
VAR_PART_SIZE=$(align_up  "$VAR_SIZE")
VARLOG_PART_SIZE=$(align_up "$VARLOG_SIZE")
VARTMP_PART_SIZE=$(align_up "$VARTMP_SIZE")
HOME_PART_SIZE=$(align_up "$HOME_SIZE")

# ── MBR layout ────────────────────────────────────────────────────────────────
# p1  primary  FAT32   /boot/firmware
# p2  primary  extended  (container for logical partitions p5–p9)
# p5  logical  ext4    /
# p6  logical  ext4    /var
# p7  logical  ext4    /var/log
# p8  logical  ext4    /var/tmp
# p9  logical  ext4    /home  ← last; the first-boot service expands this
#                               to fill remaining disk space (stage2/99-expand-home)
#
# /tmp is NOT a partition — it is mounted as tmpfs at boot (fstab). This gives
# RAM-speed I/O and avoids burning write cycles on SD cards.
#
# /home is placed last so it can be grown by extending p2 then p9 without
# moving any other partition. MBR logical partitions always start at p5 on Linux
# regardless of whether p3/p4 exist. Each logical partition is preceded by an
# Extended Boot Record (EBR); parted places it automatically — the ALIGN gap
# between partitions provides more than enough room.

BOOT_PART_START="$ALIGN"
BOOT_PART_END="$((BOOT_PART_START + BOOT_PART_SIZE - 1))"

EXT_PART_START="$((BOOT_PART_START + BOOT_PART_SIZE))"

# First logical partition: leave ALIGN bytes inside extended partition for the EBR.
ROOT_PART_START="$((EXT_PART_START + ALIGN))"
ROOT_PART_END="$((ROOT_PART_START + ROOT_PART_SIZE - 1))"

VAR_PART_START="$((ROOT_PART_END + 1 + ALIGN))"
VAR_PART_END="$((VAR_PART_START + VAR_PART_SIZE - 1))"

VARLOG_PART_START="$((VAR_PART_END + 1 + ALIGN))"
VARLOG_PART_END="$((VARLOG_PART_START + VARLOG_PART_SIZE - 1))"

VARTMP_PART_START="$((VARLOG_PART_END + 1 + ALIGN))"
VARTMP_PART_END="$((VARTMP_PART_START + VARTMP_PART_SIZE - 1))"

HOME_PART_START="$((VARTMP_PART_END + 1 + ALIGN))"
HOME_PART_END="$((HOME_PART_START + HOME_PART_SIZE - 1))"

EXT_PART_END="$HOME_PART_END"
IMG_SIZE="$((HOME_PART_END + 1))"

# ── Create image and partition table ──────────────────────────────────────────
truncate -s "${IMG_SIZE}" "${IMG_FILE}"

parted --script "${IMG_FILE}" mklabel msdos
parted --script "${IMG_FILE}" unit B mkpart primary fat32 \
    "${BOOT_PART_START}" "${BOOT_PART_END}"
parted --script "${IMG_FILE}" unit B mkpart extended \
    "${EXT_PART_START}" "${EXT_PART_END}"
parted --script "${IMG_FILE}" unit B mkpart logical ext4 \
    "${ROOT_PART_START}" "${ROOT_PART_END}"
parted --script "${IMG_FILE}" unit B mkpart logical ext4 \
    "${VAR_PART_START}" "${VAR_PART_END}"
parted --script "${IMG_FILE}" unit B mkpart logical ext4 \
    "${VARLOG_PART_START}" "${VARLOG_PART_END}"
parted --script "${IMG_FILE}" unit B mkpart logical ext4 \
    "${VARTMP_PART_START}" "${VARTMP_PART_END}"
parted --script "${IMG_FILE}" unit B mkpart logical ext4 \
    "${HOME_PART_START}" "${HOME_PART_END}"

# ── Loop device ───────────────────────────────────────────────────────────────
echo "Creating loop device..."
cnt=0
until ensure_next_loopdev && LOOP_DEV="$(losetup --show --find --partscan "$IMG_FILE")"; do
    if [ $cnt -lt 5 ]; then
        cnt=$((cnt + 1))
        echo "Error in losetup. Retrying..."
        sleep 5
    else
        echo "ERROR: losetup failed; exiting"
        exit 1
    fi
done

ensure_loopdev_partitions "$LOOP_DEV"

BOOT_DEV="${LOOP_DEV}p1"
# p2 is the extended container; no device to format or mount
ROOT_DEV="${LOOP_DEV}p5"
VAR_DEV="${LOOP_DEV}p6"
VARLOG_DEV="${LOOP_DEV}p7"
VARTMP_DEV="${LOOP_DEV}p8"
HOME_DEV="${LOOP_DEV}p9"

# ── Format ────────────────────────────────────────────────────────────────────
ROOT_FEATURES="^huge_file"
for FEATURE in 64bit; do
    if grep -q "$FEATURE" /etc/mke2fs.conf; then
        ROOT_FEATURES="^$FEATURE,$ROOT_FEATURES"
    fi
done

if [ "$BOOT_SIZE" -lt 134742016 ]; then
	FAT_SIZE=16
else
	FAT_SIZE=32
fi

mkdosfs -n bootfs -F "$FAT_SIZE" -s 1 -v "$BOOT_DEV"    > /dev/null
mkfs.ext4 -L rootfs  -O "$ROOT_FEATURES" "$ROOT_DEV"    > /dev/null
mkfs.ext4 -L var     -O "$ROOT_FEATURES" "$VAR_DEV"     > /dev/null
mkfs.ext4 -L varlog  -O "$ROOT_FEATURES" "$VARLOG_DEV"  > /dev/null
mkfs.ext4 -L vartmp  -O "$ROOT_FEATURES" "$VARTMP_DEV"  > /dev/null
mkfs.ext4 -L home    -O "$ROOT_FEATURES" "$HOME_DEV"    > /dev/null

# ── Mount in dependency order ─────────────────────────────────────────────────
# All partitions are mounted before rsync runs. This means the single rsync call
# below naturally distributes content to the correct filesystem — files under
# /home go to HOME_DEV, /var/log goes to VARLOG_DEV, etc. — without needing
# per-partition rsync invocations or explicit excludes for each directory.
mount -v "$ROOT_DEV" "${ROOTFS_DIR}" -t ext4

mkdir -p "${ROOTFS_DIR}/boot/firmware"
mkdir -p "${ROOTFS_DIR}/home"
mkdir -p "${ROOTFS_DIR}/tmp"
mkdir -p "${ROOTFS_DIR}/var"

mount -v "$VAR_DEV"    "${ROOTFS_DIR}/var"      -t ext4

# /var/log and /var/tmp must be created after VAR_DEV is mounted so the
# directories land on $VAR_DEV, not the root partition.
mkdir -p "${ROOTFS_DIR}/var/log"
mkdir -p "${ROOTFS_DIR}/var/tmp"

mount -v "$VARLOG_DEV" "${ROOTFS_DIR}/var/log"       -t ext4
mount -v "$VARTMP_DEV" "${ROOTFS_DIR}/var/tmp"       -t ext4
mount -v "$HOME_DEV"   "${ROOTFS_DIR}/home"          -t ext4
mount -v "$BOOT_DEV"   "${ROOTFS_DIR}/boot/firmware" -t vfat

# ── Populate image ────────────────────────────────────────────────────────────
rsync -aHAXx \
    --exclude /var/cache/apt/archives \
    --exclude /boot/firmware \
    "${EXPORT_ROOTFS_DIR}/" "${ROOTFS_DIR}/"
rsync -rtx "${EXPORT_ROOTFS_DIR}/boot/firmware/" "${ROOTFS_DIR}/boot/firmware/"
