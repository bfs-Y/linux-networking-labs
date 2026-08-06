#!/usr/bin/env bash
# Fix: remove the incorrectly-prefixed address and re-add it with the
# correct /28 prefix, restoring proper subnet isolation.
# Run inside ubuntulab (Ubuntu 24.04), NOT centos9 or the hypervisor.
set -euo pipefail
IF="enp7s0"
IP="10.50.0.1"
WRONG_PREFIX="24"
CORRECT_PREFIX="28"
echo "Host check: $(hostname)"
echo "Removing incorrectly-prefixed address ${IP}/${WRONG_PREFIX}..."
sudo ip addr del "${IP}/${WRONG_PREFIX}" dev "${IF}"
echo "Re-adding with correct prefix ${IP}/${CORRECT_PREFIX}..."
sudo ip addr add "${IP}/${CORRECT_PREFIX}" dev "${IF}"
echo "Fix applied. Verify with:"
echo "  ip route show 10.50.0.0/${CORRECT_PREFIX}"
echo "  (should now show the correct 16-address /28 block, not the"
echo "   wider /24 range)"
