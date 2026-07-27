#!/bin/bash
# Fix: remove the manually-assigned static IP that fell inside the DHCP
# pool range, eliminating the future address-conflict risk.
set -euo pipefail

STATIC_IP="192.168.122.50"
TARGET_IF="enp1s0"

echo "[FIX] Removing $STATIC_IP from $TARGET_IF..."
sudo ip addr del "$STATIC_IP/24" dev "$TARGET_IF"

echo "[VERIFY] Current addresses on $TARGET_IF:"
ip addr show "$TARGET_IF"
