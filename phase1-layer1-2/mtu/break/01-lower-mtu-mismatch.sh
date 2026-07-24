#!/usr/bin/env bash
# Break: lower enp1s0's MTU below the peer's configured MTU, simulating
# an MTU mismatch. Small packets (plain ping) will still work; a
# DF-bit ping at the peer's full MTU will fail once this is applied.
# Saves the original MTU so the fix script can restore it exactly,
# rather than assuming a hardcoded value.
# Run inside centos9 (CentOS Stream 9), NOT training-vm or the hypervisor.
set -euo pipefail
IF="enp1s0"
BROKEN_MTU=1400
STATE_FILE="/tmp/${IF}-original-mtu"
echo "Host check: $(hostname)"
CURRENT_MTU=$(ip -o link show dev "${IF}" | awk '{for(i=1;i<=NF;i++) if ($i=="mtu") print $(i+1)}')
echo "Current MTU on ${IF}: ${CURRENT_MTU}"
echo "${CURRENT_MTU}" > "${STATE_FILE}"
echo "Saved original MTU to ${STATE_FILE}"
echo "Setting ${IF} MTU to ${BROKEN_MTU}..."
sudo ip link set dev "${IF}" mtu "${BROKEN_MTU}"
echo "Fault reproduced. Confirm with:"
echo "  ip link show ${IF}"
echo "  from training-vm: ping -M do -s 1472 -c 4 192.168.122.207"
echo "  (should fail - packet too large for reduced MTU, DF bit set)"
