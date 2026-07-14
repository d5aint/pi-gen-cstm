#!/bin/bash

set -euo pipefail

install -m 644 files/40-local-basic-rules.rules "${ROOTFS_DIR}/etc/polkit-1/rules.d/"

# CIS 5.4.4, 5.4.5: default umask and shell timeout
install -m 644 files/shell-hardening "${ROOTFS_DIR}/etc/profile.d/"

on_chroot << EOF
# ─── 5.1.2 — /etc/crontab (600 root:root) ────────────────────────────────────
chown root:root /etc/crontab
chmod 600 /etc/crontab

# ─── 5.1.3 — /etc/cron.hourly (700 root:root) ────────────────────────────────
chown root:root /etc/cron.hourly
chmod 700 /etc/cron.hourly

# ─── 5.1.4 — /etc/cron.daily (700 root:root) ─────────────────────────────────
chown root:root /etc/cron.daily
chmod 700 /etc/cron.daily

# ─── 5.1.5 — /etc/cron.weekly (700 root:root) ────────────────────────────────
chown root:root /etc/cron.weekly
chmod 700 /etc/cron.weekly

# ─── 5.1.6 — /etc/cron.monthly (700 root:root) ───────────────────────────────
chown root:root /etc/cron.monthly
chmod 700 /etc/cron.monthly

# ─── 5.1.7 — /etc/cron.d (700 root:root) ────────────────────────────────────
chown root:root /etc/cron.d
chmod 700 /etc/cron.d
EOF