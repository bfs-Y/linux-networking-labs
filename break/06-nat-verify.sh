#!/bin/bash
# Break 06b: Prove NAT/MASQUERADE rewrites container traffic
# This isn't a destructive break — it's a hands-on verification that the
# NAT mechanism is actually firing, not just present in the ruleset.
# Belongs under Topic 6 (Firewalls) since MASQUERADE lives in the iptables nat table.

CONTAINER="nat-test"
IFACE=$(ip route | grep default | awk '{print $5}' | head -1)

echo "[SETUP] Detected interface: $IFACE"
echo "[SETUP] Starting test container..."
sudo docker run -d --name "$CONTAINER" nginx 2>/dev/null || echo "(container may already exist, continuing)"
CONTAINER_IP=$(sudo docker inspect "$CONTAINER" | grep '"IPAddress"' | head -1 | grep -oP '\d+\.\d+\.\d+\.\d+')
echo "[VERIFY] Container IP: $CONTAINER_IP"
TARGET_IP=$(dig +short example.com | head -1)
echo "[VERIFY] Capturing traffic to example.com ($TARGET_IP)..."
echo "[TEST] Capturing packets while container makes an outbound request:"
sudo timeout 5 tcpdump -i "$IFACE" -n host "$TARGET_IP" &
sleep 1
sudo docker exec "$CONTAINER" curl -s -o /dev/null http://example.com
wait
echo ""
echo "[PROOF] Expected: captured packets show HOST IP as source, NOT container IP ($CONTAINER_IP)."
echo "[PROOF] If source shown above is the host's real IP, MASQUERADE rewrote it successfully."
echo ""
echo "[VERIFY] MASQUERADE rule hit counter (should be non-zero if traffic just fired):"
sudo iptables -t nat -L -n -v | grep MASQUERADE
