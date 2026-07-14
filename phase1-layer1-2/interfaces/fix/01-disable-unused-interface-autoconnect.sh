#!/usr/bin/env bash
# Fix: stop enp7s0 from endlessly retrying DHCP on the isolated network,
# while keeping the connection profile available for future static-IP work.
# Run inside the target VM (training-vm or centos9).
set -euo pipefail

CONN_NAME="Wired connection 1"

echo "Host check: $(hostname)"
echo "Disabling autoconnect on '${CONN_NAME}' (enp7s0)..."
nmcli connection modify "${CONN_NAME}" connection.autoconnect no

echo "Disconnecting any in-progress activation attempt..."
nmcli device disconnect enp7s0 || true

echo "Verifying fix..."
nmcli device status | grep enp7s0

echo ""
echo "Expected: enp7s0 shows 'disconnected', CONNECTION '--'"
echo "Confirm no further retries with:"
echo "  sudo journalctl -u NetworkManager --since '1 minute ago' --no-pager"
