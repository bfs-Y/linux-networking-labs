#!/usr/bin/env bash
# Fix: remove the test IP from the interface first, then enslave it
# cleanly to the bond - correcting the order of operations that
# caused the silent failure in break/01-enslave-interface-with-live-ip.sh.
# Run inside ubuntulab (Ubuntu 24.04), NOT centos9 or the hypervisor.
set -euo pipefail
IF="enp7s0"
BOND="bond0"
TEST_IP="10.99.0.1/24"
echo "Host check: $(hostname)"
echo "Removing test IP from ${IF}..."
sudo ip addr del "${TEST_IP}" dev "${IF}" 2>/dev/null || echo "(address already absent)"
echo "Bringing ${IF} down before enslaving..."
sudo ip link set "${IF}" down
echo "Enslaving ${IF} to ${BOND}..."
sudo ip link set "${IF}" master "${BOND}"
echo "Bringing ${IF} back up..."
sudo ip link set "${IF}" up
echo "Fix applied. Verify with:"
echo "  cat /proc/net/bonding/${BOND}"
echo "  (expect: ${IF} listed as a Slave Interface, MII Status: up)"
