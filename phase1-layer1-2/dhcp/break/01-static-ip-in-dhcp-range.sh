#!/bin/bash
# Break: manually assign a static IP that falls INSIDE the DHCP pool range,
# creating a future address-conflict risk. No attacker — pure operational
# misconfiguration.
set -euo pipefail

STATIC_IP="192.168.122.50"
TARGET_IF="enp1s0"

echo "Host check: $(hostname)"
echo "[BREAK] Assigning static IP $STATIC_IP (inside DHCP pool range) to $TARGET_IF..."
sudo ip addr add "$STATIC_IP/24" dev "$TARGET_IF"

echo "[VERIFY] Current addresses on $TARGET_IF:"
ip addr show "$TARGET_IF"
echo ""
echo "[RISK] This IP is inside the default network's DHCP range (.2-.254)."
echo "If DHCP later hands this same address to another host, both machines"
echo "will claim 192.168.122.50 — a real address conflict."
