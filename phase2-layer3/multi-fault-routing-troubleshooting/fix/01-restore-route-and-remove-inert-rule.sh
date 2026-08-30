#!/usr/bin/env bash
# Fix: restore server's return route and remove the inert (wrong-chain)
# firewall rule on router1.
set -euo pipefail

echo "Host check: $(hostname)"
echo "--- Fault 1 fix: restoring server's return route ---"
sudo ip netns exec server ip route add 10.0.1.0/24 via 10.0.2.1

echo "--- Fault 2 fix: removing the inert OUTPUT-chain rule ---"
sudo ip netns exec router1 iptables -D OUTPUT -p icmp --icmp-type echo-reply -j DROP

echo "--- Verifying full recovery ---"
sudo ip netns exec client ping -c 3 10.0.2.2

echo ""
echo "Expect 0% packet loss above -- both faults resolved."
