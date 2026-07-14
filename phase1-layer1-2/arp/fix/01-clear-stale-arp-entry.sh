#!/usr/bin/env bash
# Fix: remove a stale/incorrect ARP entry and let the kernel re-resolve
# it naturally via a fresh ARP request -- no reboot required.
# Run inside the target VM (training-vm).
set -euo pipefail

TARGET_IP="192.168.122.207"
TARGET_IF="enp1s0"

echo "Host check: $(hostname)"
echo "Current (stale) entry:"
ip neigh show "${TARGET_IP}"

echo "Deleting stale entry..."
sudo ip neigh del "${TARGET_IP}" dev "${TARGET_IF}"

echo "Triggering fresh resolution..."
ping -c 1 "${TARGET_IP}" >/dev/null

echo "Verifying corrected entry:"
ip neigh show "${TARGET_IP}"
