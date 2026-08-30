#!/usr/bin/env bash
# Break: inject TWO independent, simultaneous faults on the client--
# router1--server topology, simulating a realistic multi-fault
# incident. Does not reveal which fault causes which symptom --
# intended to be diagnosed cold using tcpdump, ip route, and iptables.
#
# Requires the 3-namespace topology already built (see mtr-advanced
# topic's break script for the base topology, or build manually:
# client 10.0.1.2/24 -- router1 10.0.1.1/10.0.2.1 -- server 10.0.2.2/24)
set -euo pipefail

echo "Host check: $(hostname)"
echo "--- Injecting Fault 1: remove server's return route ---"
sudo ip netns exec server ip route del 10.0.1.0/24 via 10.0.2.1

echo "--- Injecting Fault 2: firewall rule on WRONG chain (OUTPUT, not FORWARD) ---"
sudo ip netns exec router1 iptables -I OUTPUT 1 -p icmp --icmp-type echo-reply -j DROP

echo ""
echo "Symptom: ping -c 3 10.0.2.2 (from client) will show 100% packet loss."
echo "Diagnose using:"
echo "  sudo ip netns exec router1 tcpdump -i any -n icmp &  (start BEFORE reproducing)"
echo "  sudo ip netns exec client ping -c 3 10.0.2.2"
echo "  sudo ip netns exec server ip route"
echo "  sudo ip netns exec router1 iptables -L OUTPUT -v -n --line-numbers"
echo ""
echo "Fix with: fix/01-restore-route-and-remove-inert-rule.sh"
