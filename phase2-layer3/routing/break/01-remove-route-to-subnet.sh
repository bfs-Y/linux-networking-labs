#!/usr/bin/env bash
# Break: ensure NO route exists to 10.50.0.0/28, simulating the real
# starting condition - a remote gateway/host was never told about a
# subnet that genuinely exists elsewhere on the network.
# PREREQUISITE: ubuntulab must already have 10.50.0.1/28 configured on
# enp7s0 (sudo ip addr add 10.50.0.1/28 dev enp7s0) before this is
# meaningful to test.
# Run inside centos9 (CentOS Stream 9), NOT ubuntulab or the hypervisor.
set -euo pipefail
NETWORK="10.50.0.0/28"
echo "Host check: $(hostname)"
echo "Current route (if any) for ${NETWORK}:"
ip route show "${NETWORK}" || echo "(no route currently exists)"
echo "Removing any existing route to ${NETWORK} (if present)..."
sudo ip route del "${NETWORK}" 2>/dev/null || echo "(none to remove - already in the broken state)"
echo "Fault reproduced. Confirm with:"
echo "  ip route get 10.50.0.1"
echo "  (should route via the default gateway, not directly)"
echo "  ping -c 2 10.50.0.1"
echo "  (should fail - 100% loss, silent, no 'unreachable' message)"
echo "Fix: ./phase2-layer3/routing/fix/01-add-route-to-subnet.sh"
