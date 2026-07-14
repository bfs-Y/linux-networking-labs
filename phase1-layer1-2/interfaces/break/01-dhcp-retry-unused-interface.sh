#!/usr/bin/env bash
# Break: re-enable DHCP retry loop on enp7s0 (isolated network, no DHCP by design)
# Run inside the target VM (training-vm or centos9), NOT the hypervisor.
#
# Reproduces: NetworkManager endlessly retrying DHCP on an interface
# attached to a libvirt network that intentionally has no DHCP server.
set -euo pipefail

CONN_NAME="Wired connection 1"

echo "Host check: $(hostname)"
echo "Re-enabling autoconnect on '${CONN_NAME}' (enp7s0)..."
nmcli connection modify "${CONN_NAME}" connection.autoconnect yes

echo "Bringing enp7s0 up to trigger DHCP attempt..."
nmcli device connect enp7s0 || true

echo "Fault reproduced. Confirm with:"
echo "  nmcli device status"
echo "  sudo journalctl -u NetworkManager --since '2 minutes ago' --no-pager"
