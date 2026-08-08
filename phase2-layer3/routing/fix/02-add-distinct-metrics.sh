#!/usr/bin/env bash
# Fix: remove the ambiguous route state and re-add both routes with
# explicit, DISTINCT metrics, so they genuinely coexist as a real
# primary/backup pair instead of one silently replacing the other.
# Run inside centos9 (CentOS Stream 9), NOT ubuntulab or the hypervisor.
set -euo pipefail
NETWORK="10.50.0.0/28"
PRIMARY_VIA="192.168.122.226"
BACKUP_VIA="192.168.122.230"
echo "Host check: $(hostname)"
echo "Clearing any existing route(s) to ${NETWORK}..."
sudo ip route del "${NETWORK}" 2>/dev/null || true
echo "Adding primary route (metric 100)..."
sudo ip route add "${NETWORK}" via "${PRIMARY_VIA}" metric 100
echo "Adding backup route (metric 200)..."
sudo ip route add "${NETWORK}" via "${BACKUP_VIA}" metric 200
echo "Verifying both routes coexist:"
ip route show "${NETWORK}"
echo "Fix applied. Confirm with:"
echo "  ip route get 10.50.0.1"
echo "  (should select the LOWER metric route: via ${PRIMARY_VIA})"
