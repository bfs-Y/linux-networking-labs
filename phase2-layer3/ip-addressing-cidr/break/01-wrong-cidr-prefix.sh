#!/usr/bin/env bash
# Break: assign an address with the WRONG CIDR prefix (/24 instead of
# the intended /28), simulating a common real mistake. This silently
# breaks subnet isolation - the interface now believes a much larger
# range of addresses is directly reachable than actually intended,
# and route show reveals the mismatch immediately once checked.
# Run inside ubuntulab (Ubuntu 24.04), NOT centos9 or the hypervisor.
set -euo pipefail
IF="enp7s0"
IP="10.50.0.1"
WRONG_PREFIX="24"
echo "Host check: $(hostname)"
echo "Current addresses on ${IF}:"
ip addr show "${IF}"
echo "Assigning ${IP} with WRONG prefix /${WRONG_PREFIX} (intended: /28)..."
sudo ip addr add "${IP}/${WRONG_PREFIX}" dev "${IF}"
echo "Fault reproduced. Confirm with:"
echo "  ip route show 10.50.0.0/${WRONG_PREFIX}"
echo "  (shows a /24 - 256 addresses - treated as directly reachable,"
echo "   not the intended /28 of 16 addresses; subnet isolation is"
echo "   effectively broken - devices well outside the real /28 would"
echo "   now be treated as local/same-subnet)"
echo "Fix: ./phase2-layer3/ip-addressing-cidr/fix/01-correct-cidr-prefix.sh"
