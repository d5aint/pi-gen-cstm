#!/bin/bash

set -euo pipefail


on_chroot << EOF
# ─── 5.2.1 — /etc/ssh/sshd_config (600 root:root) ────────────────────────────────────
chown root:root /etc/ssh/sshd_config
chmod 600 /etc/ssh/sshd_config
EOF