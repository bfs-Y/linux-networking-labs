#!/usr/bin/env bash
# Break: attempt to enslave an interface to a bond while it still has
# an IP address assigned. This fails SILENTLY - no error is returned,
# but the interface never actually becomes an active slave. Confirmed
# only by checking /proc/net/bonding/bond0 directly, not by the
# command's exit status or ip link show output alone.
# Run inside ubuntulab (Ubuntu 24.04), NOT centos9 or the hypervisor.
# Scoped to enp7s0 deliberately - safe to test, no live SSH traffic
# depends on it (unlike enp1s0).
set -euo pipefail
IF="enp7s0"
BOND="bond0"
TEST_IP="10.99.0.1/24"
echo "Host check: $(hostname)"
echo "Ensuring bond0 exists with active-backup mode and miimon set..."
sudo ip link add "${BOND}" type bond mode active-backup 2>/dev/null || echo "(bond0 already exists)"
sudo ip link set "${BOND}" type bond miimon 100 2>/dev/null || true
sudo ip link set "${BOND}" up
echo "Assigning a test IP to ${IF} (this is the mistake being simulated)..."
sudo ip addr add "${TEST_IP}" dev "${IF}" 2>/dev/null || echo "(address already present)"
echo "Attempting to enslave ${IF} while it still has an IP..."
sudo ip link set "${IF}" master "${BOND}" 2>&1 || echo "(command returned no visible error either way)"
echo "Fault reproduced (or not - check carefully). Confirm with:"
echo "  cat /proc/net/bonding/${BOND}"
echo "  (expect: Currently Active Slave: None, or ${IF} missing from slave list)"
echo "Fix: ./phase1-layer1-2/bonding/fix/01-remove-ip-then-enslave.sh"
