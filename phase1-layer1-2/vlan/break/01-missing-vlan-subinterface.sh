#!/usr/bin/env bash
# Break: simulate a colleague's mistake - assigning an address directly
# to the PARENT interface instead of creating a proper VLAN sub-interface.
# Traffic sent this way is genuinely untagged (no 802.1Q header at all),
# reproducing the "downstream sees untagged frames" symptom for real.
# Run inside ubuntulab (Ubuntu 24.04), NOT centos9 or the hypervisor.
set -euo pipefail
PARENT_IF="enp1s0"
WRONG_IP="10.100.0.10/24"
echo "Host check: $(hostname)"
echo "Current addresses on ${PARENT_IF}:"
ip addr show "${PARENT_IF}"
echo "Incorrectly assigning VLAN-intended address directly to parent interface..."
sudo ip addr add "${WRONG_IP}" dev "${PARENT_IF}"
echo "Fault reproduced. Confirm untagged traffic with:"
echo "  sudo tcpdump -i ${PARENT_IF} -e -nn -vv host 10.100.0.10"
echo "  (frames will show NO 802.1Q/ethertype 0x8100 - genuinely untagged)"
echo "Fix: ./phase1-layer1-2/vlan/fix/01-remove-wrong-address-create-subinterface.sh"
