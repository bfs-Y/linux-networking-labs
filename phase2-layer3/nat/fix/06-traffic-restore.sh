#!/bin/bash
# Fix 06: Remove the ICMP drop rule
# Pairs with: break/06-traffic-drop.sh

TARGET="8.8.8.8"

echo "[FIX] Removing ICMP drop rule for $TARGET..."
sudo iptables -D OUTPUT -d "$TARGET" -p icmp -j DROP
echo "[VERIFY] Rule removed:"
sudo iptables -L OUTPUT -n -v | grep "$TARGET" || echo "Confirmed clean — no drop rule remains"
echo "[TEST] Ping should succeed now:"
ping -c 2 "$TARGET"
