#!/bin/bash
# Break 06: Silently drop outbound ICMP to a target, simulating "request sent, no reply"
# Effect: ping shows 100% packet loss, tcpdump shows requests leaving with no replies
# Recovery: fix/06-traffic-restore.sh

TARGET="8.8.8.8"

echo "[BREAK] Dropping outbound ICMP to $TARGET..."
sudo iptables -I OUTPUT -d "$TARGET" -p icmp -j DROP
echo "[VERIFY] Rule added:"
sudo iptables -L OUTPUT -n -v | grep "$TARGET"
echo "[TEST] Ping should show 100% loss, no replies:"
ping -c 2 "$TARGET"
