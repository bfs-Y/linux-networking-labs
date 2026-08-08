#!/usr/bin/env bash
# Break: add a route to a destination that already has a route,
# WITHOUT specifying a distinct metric - simulating the mistake of
# assuming this creates a backup/failover route. It actually silently
# REPLACES the original route instead, since equal/unspecified
# metrics are ambiguous to the kernel.
# Run inside centos9 (CentOS Stream 9), NOT ubuntulab or the hypervisor.
set -euo pipefail
NETWORK="10.50.0.0/28"
PRIMARY_VIA="192.168.122.226"
SECOND_VIA="192.168.122.230"
echo "Host check: $(hostname)"
echo "Ensuring a clean starting state..."
sudo ip route del "${NETWORK}" 2>/dev/null || true
echo "Adding first route (no explicit metric)..."
sudo ip route add "${NETWORK}" via "${PRIMARY_VIA}"
echo "Current state:"
ip route show "${NETWORK}"
echo "Adding SECOND route to the same destination, also no explicit metric..."
sudo ip route add "${NETWORK}" via "${SECOND_VIA}" 2>&1 || echo "(add may have failed or replaced silently - check below)"
echo "Fault reproduced. Confirm with:"
echo "  ip route show ${NETWORK}"
echo "  (expect: only ONE route shown, the original via ${PRIMARY_VIA}"
echo "   is likely GONE, not a genuine backup as intended)"
echo "Fix: ./phase2-layer3/routing/fix/02-add-distinct-metrics.sh"
