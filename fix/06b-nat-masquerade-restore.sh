#!/bin/bash
# Fix 06b: Restore MASQUERADE on the correct outbound interface
set -euo pipefail

IFACE=$(ip route | grep default | awk '{print $5}' | head -1)
echo "[FIX] Restoring MASQUERADE on interface: $IFACE"
sudo iptables -t nat -A POSTROUTING -o "$IFACE" -j MASQUERADE

echo "[FIX] Re-run verify/06-nat-verify.sh — proof output should now show"
echo "the HOST IP as source again, confirming NAT is restored."
