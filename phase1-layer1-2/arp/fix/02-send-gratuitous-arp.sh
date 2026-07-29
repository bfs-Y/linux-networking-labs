#!/usr/bin/env bash
# Fix: send a gratuitous ARP announcing this host's own IP, correcting
# any peer holding a stale (non-permanent) cached MAC for it - e.g.
# after a VIP failover. Does NOT work against PERMANENT peer entries
# or peers with arp_accept=0 and no prior entry (see postmortem 02).
# Run inside ubuntulab (Ubuntu 24.04), NOT centos9 or the hypervisor.
set -euo pipefail
OWN_IP="192.168.122.227"
TARGET_IF="enp1s0"
echo "Host check: $(hostname)"
echo "Announcing ${OWN_IP} via gratuitous ARP on ${TARGET_IF}..."
sudo arping -U -I "${TARGET_IF}" -c 3 "${OWN_IP}"
echo "Fix sent. Verify on centos9:"
echo "  ip neigh show ${OWN_IP}"
echo "  (should now show the real MAC, state STALE)"
