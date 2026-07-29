#!/usr/bin/env bash
# Break: simulate a peer host holding a stale (but non-permanent) cached
# MAC for a VIP, as if a failover just occurred and this peer hasn't
# learned the new owner's MAC yet. Uses nud reachable explicitly, since
# ip neigh replace defaults to PERMANENT with no nud flag - PERMANENT
# entries are immune to gratuitous ARP by design (see postmortem 02).
# Run inside centos9 (CentOS Stream 9), NOT ubuntulab or the hypervisor.
set -euo pipefail
TARGET_IP="192.168.122.227"   # ubuntulab (the VIP owner)
FAKE_MAC="00:11:22:33:44:99"
TARGET_IF="enp1s0"
echo "Host check: $(hostname)"
echo "Current neighbor entry for ${TARGET_IP}:"
ip neigh show "${TARGET_IP}" || echo "(no existing entry)"
echo "Injecting stale (non-permanent) entry with wrong MAC..."
sudo ip neigh replace "${TARGET_IP}" lladdr "${FAKE_MAC}" nud reachable dev "${TARGET_IF}"
echo "Fault reproduced. Confirm with:"
echo "  ip neigh show ${TARGET_IP}"
echo "  (should show ${FAKE_MAC}, state REACHABLE - not PERMANENT)"
echo "Fix from ubuntulab: ./phase1-layer1-2/arp/fix/02-send-gratuitous-arp.sh"
