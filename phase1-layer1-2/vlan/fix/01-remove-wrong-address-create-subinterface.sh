#!/usr/bin/env bash
# Fix: remove the wrongly-placed address from the parent interface, then
# create a proper VLAN sub-interface and assign the address there instead.
# Run inside ubuntulab (Ubuntu 24.04), NOT centos9 or the hypervisor.
set -euo pipefail
PARENT_IF="enp1s0"
VLAN_IF="enp1s0.100"
VLAN_ID="100"
WRONG_IP="10.100.0.10/24"
echo "Host check: $(hostname)"
echo "Removing incorrectly-placed address from parent interface..."
sudo ip addr del "${WRONG_IP}" dev "${PARENT_IF}"
echo "Creating proper VLAN sub-interface..."
sudo ip link add link "${PARENT_IF}" name "${VLAN_IF}" type vlan id "${VLAN_ID}"
sudo ip link set "${VLAN_IF}" up
sudo ip addr add "${WRONG_IP}" dev "${VLAN_IF}"
echo "Fix applied. Verify with:"
echo "  ip -d link show ${VLAN_IF}"
echo "  sudo tcpdump -i ${PARENT_IF} -e -nn -vv 'vlan ${VLAN_ID}'"
echo "  (frames should now show ethertype 802.1Q, vlan ${VLAN_ID} - genuinely tagged)"
