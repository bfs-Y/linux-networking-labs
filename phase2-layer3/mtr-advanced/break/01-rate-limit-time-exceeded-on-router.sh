#!/usr/bin/env bash
# Break: build a genuine 3-namespace, 2-hop network path, then rate-limit
# ICMP time-exceeded messages on the intermediate router (not the final
# destination). Demonstrates correct attribution of mtr/traceroute loss
# to a specific hop, and that echo-request rules do NOT affect
# traceroute-style probing -- only time-exceeded (type 11) on OUTPUT does.
set -euo pipefail

echo "Host check: $(hostname)"
echo "--- Building topology: client -- router1 -- server ---"

sudo ip netns add client 2>/dev/null || true
sudo ip netns add router1 2>/dev/null || true
sudo ip netns add server 2>/dev/null || true

sudo ip link add veth-client type veth peer name veth-r1a 2>/dev/null || true
sudo ip link add veth-r1b type veth peer name veth-server 2>/dev/null || true

sudo ip link set veth-client netns client 2>/dev/null || true
sudo ip link set veth-r1a netns router1 2>/dev/null || true
sudo ip link set veth-r1b netns router1 2>/dev/null || true
sudo ip link set veth-server netns server 2>/dev/null || true

sudo ip netns exec client ip link set lo up
sudo ip netns exec client ip link set veth-client up
sudo ip netns exec client ip addr add 10.0.1.2/24 dev veth-client 2>/dev/null || true

sudo ip netns exec router1 ip link set lo up
sudo ip netns exec router1 ip link set veth-r1a up
sudo ip netns exec router1 ip addr add 10.0.1.1/24 dev veth-r1a 2>/dev/null || true
sudo ip netns exec router1 ip link set veth-r1b up
sudo ip netns exec router1 ip addr add 10.0.2.1/24 dev veth-r1b 2>/dev/null || true
sudo ip netns exec router1 sysctl -w net.ipv4.ip_forward=1

sudo ip netns exec server ip link set lo up
sudo ip netns exec server ip link set veth-server up
sudo ip netns exec server ip addr add 10.0.2.2/24 dev veth-server 2>/dev/null || true

sudo ip netns exec client ip route add 10.0.2.0/24 via 10.0.1.1 2>/dev/null || true
sudo ip netns exec server ip route add 10.0.1.0/24 via 10.0.2.1 2>/dev/null || true

echo "--- Applying rate limit to router1's OUTPUT (time-exceeded, not echo-request) ---"
sudo ip netns exec router1 iptables -I OUTPUT 1 -p icmp --icmp-type time-exceeded -j DROP
sudo ip netns exec router1 iptables -I OUTPUT 1 -p icmp --icmp-type time-exceeded -m limit --limit 1/second --limit-burst 1 -j ACCEPT

echo ""
echo "Symptom: from client, run:"
echo "  sudo ip netns exec client mtr -r -c 10 10.0.2.2"
echo "Expect: measurable loss at hop 1 (10.0.1.1), 0% loss at hop 2 (10.0.2.2)."
echo "Fix with: fix/01-remove-time-exceeded-limit.sh"
