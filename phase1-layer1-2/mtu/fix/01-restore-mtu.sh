#!/usr/bin/env bash
# Fix: restore enp1s0's MTU to the value saved before the break script
# ran, rather than assuming a hardcoded default.
# Run inside centos9 (CentOS Stream 9), NOT training-vm or the hypervisor.
set -euo pipefail
IF="enp1s0"
STATE_FILE="/tmp/${IF}-original-mtu"
echo "Host check: $(hostname)"
if [ ! -f "${STATE_FILE}" ]; then
  echo "ERROR: ${STATE_FILE} not found - was the break script ever run?"
  exit 1
fi
ORIGINAL_MTU=$(cat "${STATE_FILE}")
echo "Restoring ${IF} MTU to saved value: ${ORIGINAL_MTU}"
sudo ip link set dev "${IF}" mtu "${ORIGINAL_MTU}"
echo "Verifying:"
ip link show "${IF}"
echo "Fix applied. Confirm from training-vm:"
echo "  ping -M do -s 1472 -c 4 192.168.122.207   # should now succeed"
