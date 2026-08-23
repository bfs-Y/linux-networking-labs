#!/usr/bin/env bash
# Fix: remove the time-exceeded rate limit from router1's OUTPUT chain,
# restoring normal hop-1 responsiveness in mtr/traceroute.
set -euo pipefail

echo "Host check: $(hostname)"
echo "--- Rules before fix ---"
sudo ip netns exec router1 iptables -L OUTPUT -v -n --line-numbers

echo "--- Removing time-exceeded rate limit ---"
sudo ip netns exec router1 iptables -D OUTPUT -p icmp --icmp-type time-exceeded -m limit --limit 1/second --limit-burst 1 -j ACCEPT
sudo ip netns exec router1 iptables -D OUTPUT -p icmp --icmp-type time-exceeded -j DROP

echo "--- Rules after fix ---"
sudo ip netns exec router1 iptables -L OUTPUT -v -n --line-numbers

echo ""
echo "Verify with: sudo ip netns exec client mtr -r -c 10 10.0.2.2"
echo "Expect: 0% loss on both hops again."
