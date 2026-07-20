#!/usr/bin/env bash
# Break: systematic fault-injection sequence for a bridge + veth + namespace
# lab. Builds the correct lab topology, then tears it down one piece at a
# time so each dependency can be observed in isolation. Run on the
# hypervisor as the user who will own the interfaces.
#
# Requires: bridge-utils / iproute2 (ip, bridge commands)
set -euo pipefail

echo "Host check: $(hostname)"

echo "--- Building lab topology ---"
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

echo "--- Baseline check (should succeed, 0% loss) ---"
ping -c 2 10.10.10.2

echo ""
echo "Lab topology built. Run each break scenario manually, in order,"
echo "predicting the outcome before each command:"
echo ""
echo "BREAK 1 (bring down host-side veth end):"
echo "  sudo ip link set veth-host down"
echo "  ip link show veth-host"
echo "  sudo ip netns exec lab1 ip link show eth0"
echo "  ping -c 3 10.10.10.2"
echo "  -- recover: sudo ip link set veth-host up"
echo ""
echo "BREAK 2 (bring down namespace-side veth end):"
echo "  sudo ip netns exec lab1 ip link set eth0 down"
echo "  ip link show veth-host"
echo "  sudo ip netns exec lab1 ip link show eth0"
echo "  ping -c 3 10.10.10.2"
echo "  -- recover: sudo ip netns exec lab1 ip link set eth0 up"
echo ""
echo "BREAK 3 (delete the namespace):"
echo "  sudo ip netns del lab1"
echo "  bridge link"
echo "  ip link show veth-host"
echo "  -- expect: veth-host is destroyed too (same kernel object,"
echo "     both ends of a veth pair are removed together)"
echo ""
echo "BREAK 4 (delete the now-empty bridge):"
echo "  sudo ip link delete br0"
echo "  ip link show br0"
echo "  bridge link"
echo "  -- expect: clean removal, no dependent objects remain"
