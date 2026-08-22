#!/usr/bin/env bash
# Fix: remove the ICMP rate-limit rules, restoring normal (unlimited)
# ping response behavior.
set -euo pipefail

echo "Host check: $(hostname)"
echo "--- Rules before fix ---"
sudo iptables -L INPUT -v -n --line-numbers | head -5

echo "--- Removing ICMP rate-limit rules ---"
sudo iptables -D INPUT -p icmp --icmp-type echo-request -m limit --limit 1/second --limit-burst 1 -j ACCEPT
sudo iptables -D INPUT -p icmp --icmp-type echo-request -j DROP

echo "--- Rules after fix ---"
sudo iptables -L INPUT -v -n --line-numbers | head -5

echo ""
echo "Verify with a normal ping test from another host -- should show 0% loss again."
