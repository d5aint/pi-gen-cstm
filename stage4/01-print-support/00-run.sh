#!/bin/bash

set -euo pipefail

on_chroot <<EOF
#adduser "$FIRST_USER_NAME" lpadmin
EOF
