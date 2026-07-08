#!/bin/bash
# Topic 2c: Capture and decode a real TCP handshake

IFACE=$(ip route | grep default | awk '{print $5}' | head -1)
TARGET_IP=$(dig +short example.com | head -1)
PCAP="/tmp/tcp-handshake.pcap"

echo "[SAFETY CHECK] You are about to capture traffic on:"
echo "  Hostname: $(hostname)"
echo "  Interface: $IFACE"
read -p "Confirm this is the intended TRAINING machine, not your host (y/N): " CONFIRM
if [ "$CONFIRM" != "y" ]; then
    echo "[ABORTED] Confirmation not given. No changes made."
    exit 1
fi

echo "[SETUP] Target: example.com ($TARGET_IP)"
echo ""
echo "=== CAPTURING FULL TCP CONVERSATION ==="
sudo tcpdump -i "$IFACE" -n "host $TARGET_IP and tcp port 80" -w "$PCAP" &
TCPDUMP_PID=$!
sleep 2
curl -s -o /dev/null http://example.com
sleep 1
sudo kill $TCPDUMP_PID 2>/dev/null
wait $TCPDUMP_PID 2>/dev/null
echo ""
echo "=== READING CAPTURE ==="
sudo tcpdump -r "$PCAP" -n
echo ""
echo "[READ THIS] Identify each flag combination above:"
echo "  [S]   = SYN       — client requests connection"
echo "  [S.]  = SYN+ACK   — server confirms, sends own SYN"
echo "  [.]   = ACK       — client confirms, handshake complete"
echo "  [P.]  = PUSH+ACK  — actual data (GET request / HTTP response)"
echo "  [F.]  = FIN+ACK   — graceful connection close"
echo ""
echo "[VERIFY] seq/ack math: SYN's seq + 1 should equal SYN-ACK's ack"
