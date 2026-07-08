#!/bin/bash
# Simulate a poisoned ARP cache entry — dynamic, not permanent
# Mimics real ARP poisoning (unsolicited dynamic entry)

GATEWAY="192.168.122.1"
FAKE_MAC="aa:bb:cc:dd:ee:ff"
IFACE=$(ip route | grep default | awk '{print $5}' | head -1)

echo "[SAFETY CHECK] You are about to modify the ARP cache on:"
echo "  Hostname: $(hostname)"
echo "  Interface: $IFACE"
echo "  Target gateway entry: $GATEWAY"
read -p "Confirm this is the intended TRAINING machine, not your host (y/N): " CONFIRM
if [ "$CONFIRM" != "y" ]; then
    echo "[ABORTED] Confirmation not given. No changes made."
    exit 1
fi

echo "[BREAK] Injecting fake ARP entry for $GATEWAY (nud reachable)"
sudo ip neigh replace "$GATEWAY" dev "$IFACE" lladdr "$FAKE_MAC" nud reachable
echo "[BREAK] ARP cache now shows:"
ip neigh show | grep "$GATEWAY"
echo "[BREAK] All traffic to gateway now goes to $FAKE_MAC"
