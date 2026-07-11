#!/usr/bin/env bash
set -euo pipefail

OUTDIR="$(cd "$(dirname "$0")" && pwd)"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
PCAP="${OUTDIR}/baseline-virbr0-${TIMESTAMP}.pcap"
TRAINING_VM_IP="192.168.122.227"
CENTOS_VM_IP="192.168.122.207"
TRAINING_VM_USER="training"

echo "Host check: $(hostname)"
if ! ip link show virbr0 >/dev/null 2>&1; then
  echo "ERROR: virbr0 not found on this host." >&2
  exit 1
fi

echo "Starting 60s baseline capture on virbr0 -> ${PCAP}"
timeout 60 tcpdump -i virbr0 -n -e -w "${PCAP}" &
TCPDUMP_PID=$!

sleep 2
echo "Triggering known-good traffic FROM training-vm via SSH..."
ssh -o BatchMode=yes -o ConnectTimeout=5 "${TRAINING_VM_USER}@${TRAINING_VM_IP}" \
  "ping -c 5 ${CENTOS_VM_IP}" || \
  echo "WARNING: remote ping via SSH failed"

if wait "${TCPDUMP_PID}"; then
  TCPDUMP_EXIT=0
else
  TCPDUMP_EXIT=$?
fi
if [ "${TCPDUMP_EXIT}" -ne 0 ] && [ "${TCPDUMP_EXIT}" -ne 124 ]; then
  echo "ERROR: tcpdump exited unexpectedly with code ${TCPDUMP_EXIT}" >&2
  exit 1
fi
echo "Capture complete: ${PCAP}"

ip a > "${OUTDIR}/baseline-ip-a-${TIMESTAMP}.txt"
ip neigh > "${OUTDIR}/baseline-ip-neigh-${TIMESTAMP}.txt"
ip route > "${OUTDIR}/baseline-ip-route-${TIMESTAMP}.txt"
ss -tuln > "${OUTDIR}/baseline-ss-${TIMESTAMP}.txt"

PACKET_COUNT=$(tcpdump -r "${PCAP}" 2>/dev/null | wc -l)
echo "Captured ${PACKET_COUNT} packets."
if [ "${PACKET_COUNT}" -lt 5 ]; then
  echo "WARNING: packet count is suspiciously low."
  exit 1
fi
