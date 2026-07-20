#!/usr/bin/env bash
# Fix: fully rebuild the bridge + veth + namespace lab topology from a
# clean slate, after any/all break scenarios have been run and torn
# everything down. Idempotent-ish: cleans up any leftover state first.
set -euo pipefail

echo "Host check: $(hostname)"

echo "--- Cleaning up any leftover state ---"
sudo ip netns del lab1 2>/dev/null || true
sudo ip link delete veth-host 2>/dev/null || true
sudo ip link delete br0 2>/dev/null || true

echo "--- Rebuilding from scratch ---"
sudo ip link add br0 type bridge
sudo ip link set br0 up
sudo ip addr add 10.10.10.1/24 dev br0
sudo ip link add veth-host type veth peer name veth-ns
sudo ip link set veth-host master br0
sudo ip link set veth-host up
sudo ip netns add lab1
sudo ip link set veth-ns netns lab1
sudo ip netns exec lab1 ip link set veth-ns name eth0
sudo ip netns exec lab1 ip link set lo up
sudo ip netns exec lab1 ip link set eth0 up
sudo ip netns exec lab1 ip addr add 10.10.10.2/24 dev eth0

echo "--- Verifying ---"
ping -c 2 10.10.10.2

echo ""
echo "Lab topology rebuilt and verified: 0% packet loss expected above."
