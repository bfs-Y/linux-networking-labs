#!/bin/bash
# Break 03: Point DNS resolution at an unreachable server and measure
# the real cost of a resolver that never responds - closing the open
# item from postmortem/03 (nsswitch-reorder-latency.md), which found
# negligible cost against a fast local resolver but left "slow/
# unreachable resolver" cost untested.
#
# Uses resolvectl's per-interface override (temporary, reversible with
# `resolvectl revert`) instead of editing /etc/resolv.conf or
# nsswitch.conf directly - safer, single command to undo.
#
# Uses `getent hosts` (goes through the system resolver / NSS chain,
# respects resolvectl's per-interface config) rather than `dig @server`
# (which would hardcode a target server and ignore the resolvectl
# change entirely - caught before running, not after).
set -euo pipefail

IFACE="${1:-enp1s0}"
DEAD_IP="192.168.122.250"   # confirmed unreachable via ping test - not
                              # cached in `ip neigh show`, 100% packet
                              # loss, nothing else known to be at this
                              # address on this subnet
TARGET="wikipedia.org"

echo "[BASELINE] Current DNS config for $IFACE:"
resolvectl status "$IFACE" | grep -A1 "DNS Servers"

echo ""
echo "[FLUSH] Clearing cache before baseline measurement..."
sudo resolvectl flush-caches

echo "[BASELINE] Timing lookup of $TARGET via system resolver (normal config):"
time getent hosts "$TARGET"

echo ""
echo "[BREAK] Redirecting $IFACE's DNS to unreachable $DEAD_IP..."
sudo resolvectl dns "$IFACE" "$DEAD_IP"

echo "[BREAK] New DNS config for $IFACE:"
resolvectl status "$IFACE" | grep -A1 "DNS Servers"

echo ""
echo "[FLUSH] Clearing cache before dead-resolver measurement..."
sudo resolvectl flush-caches

echo "[TEST] Timing lookup of $TARGET via system resolver (now pointed at"
echo "the unreachable server - this WILL hang until timeout, that's the point):"
time getent hosts "$TARGET" || echo "[LOOKUP FAILED AS EXPECTED]"

echo ""
echo "[PROOF] Compare the two 'real' time values above. The dead-resolver"
echo "lookup should take dramatically longer (waiting on a timeout),"
echo "proving the real-world cost the reordering lab's open item flagged"
echo "as untested."
echo ""
echo "Recovery: sudo resolvectl revert $IFACE"
echo "Or run: fix/03-restore-resolver.sh"
