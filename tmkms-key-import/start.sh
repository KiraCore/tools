#!/bin/bash
set +e && source "/etc/profile" &>/dev/null && set -e

python3 /home/$SUDO_USER/tools/tmkms-key-import/tmkms-key-import.py "$1"