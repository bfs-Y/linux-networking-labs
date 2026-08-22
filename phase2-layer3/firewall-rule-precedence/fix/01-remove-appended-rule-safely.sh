#!/usr/bin/env bash
# Fix: safely remove a specific appended rule WITHOUT flushing the
# entire chain (which would also remove ufw's own rules).
set -euo pipefail

echo "Host check: $(hostname)"
echo "--- Removing only the specific appended rule (not a chain flush) ---"
sudo iptables -D INPUT -p icmp --icmp-type echo-request -j DROP

echo "--- Confirming ufw's own chains are untouched ---"
sudo iptables -L INPUT -v -n --line-numbers

echo ""
echo "If INPUT was ever accidentally flushed entirely (iptables -F INPUT),"
echo "the correct recovery is NOT to manually rebuild rules -- run:"
echo "  sudo ufw reload"
echo "This rebuilds ufw's full chain structure from /etc/ufw/ configs."
