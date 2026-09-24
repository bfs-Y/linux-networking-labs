#!/bin/bash
# Observe: capture the DORA (Discover/Offer/Request/Ack) sequence live
# by forcing a DHCP renewal while tcpdump watches. No fault — pure
# mechanism observation.
set -euo pipefail

TARGET_IF="enp1s0"
CONN_NAME="netplan-enp1s0"

echo "Host check: $(hostname)"
echo "[SETUP] Starting tcpdump on DHCP ports 67/68..."
sudo tcpdump -i "$TARGET_IF" -n port 67 or port 68 -w /tmp/dhcp-capture.pcap &
TCPDUMP_PID=$!
sleep 2

echo "[TRIGGER] Forcing DHCP release and renewal..."
sudo nmcli connection down "$CONN_NAME"
sudo nmcli connection up "$CONN_NAME"

sleep 5
sudo kill $TCPDUMP_PID 2>/dev/null || true

echo "[CAPTURE] DORA sequence:"
sudo tcpdump -r /tmp/dhcp-capture.pcap -n
