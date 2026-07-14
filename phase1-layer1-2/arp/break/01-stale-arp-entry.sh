#!/usr/bin/env bash
# Break: insert a stale/incorrect ARP entry for a peer, simulating what
# happens when a host's MAC changes (VM rebuilt, NIC replaced) but the
# local neighbor cache still holds the old mapping.
# Run inside the target VM (training-vm), NOT the hypervisor.
set -euo pipefail

TARGET_IP="192.168.122.207"       # centos9
FAKE_MAC="00:11:22:33:44:55"      # deliberately wrong MAC
TARGET_IF="enp1s0"

echo "Host check: $(hostname)"
echo "Current neighbor entry for ${TARGET_IP}:"
ip neigh show "${TARGET_IP}" || echo "(no existing entry)"

echo "Injecting stale/incorrect ARP entry..."
sudo ip neigh replace "${TARGET_IP}" lladdr "${FAKE_MAC}" dev "${TARGET_IF}" nud permanent

echo "Fault reproduced. Confirm with:"
echo "  ip neigh show ${TARGET_IP}"
echo "  ping -c 2 ${TARGET_IP}   # should fail or go to the wrong MAC"
