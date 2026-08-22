#!/usr/bin/env bash
# Break: rate-limit ICMP echo replies to simulate a router/host that
# deliberately deprioritizes ping/traceroute traffic while still
# forwarding real application traffic normally. Demonstrates that
# ping "loss" alone does not prove the path is broken.
#
# IMPORTANT: inserts rules at the TOP of INPUT (position 1) so they
# are evaluated BEFORE ufw's own unconditional ICMP ACCEPT rule in
# ufw-before-input. Appending with -A here would have no effect on
# a ufw-managed host -- see postmortem/03-iptables-flush-ufw-precedence.md
set -euo pipefail

echo "Host check: $(hostname)"
echo "--- Inserting ICMP rate-limit rules at top of INPUT ---"
sudo iptables -I INPUT 1 -p icmp --icmp-type echo-request -j DROP
sudo iptables -I INPUT 1 -p icmp --icmp-type echo-request -m limit --limit 1/second --limit-burst 1 -j ACCEPT

echo "--- Current rule order (rate-limit rules should be at positions 1-2) ---"
sudo iptables -L INPUT -v -n --line-numbers | head -5

echo ""
echo "Symptom: from another host, ping this machine fast (e.g."
echo "  ping -c 10 -i 0.2 <this-host-ip>"
echo "expect ~80% packet loss. Then test real traffic from the same"
echo "host to prove it's unaffected:"
echo "  curl -s -o /dev/null -w 'HTTP %{http_code} in %{time_total}s\n' http://<this-host-ip>"
echo "expect a clean 200 response every time, despite the ping loss."
echo ""
echo "Fix with: fix/02-remove-icmp-rate-limit.sh"
