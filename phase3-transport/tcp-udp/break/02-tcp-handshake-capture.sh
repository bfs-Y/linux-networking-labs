#!/bin/bash
# Topic 02: Capture and decode a real TCP handshake
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
rm -f "$PCAP"
sudo tcpdump -i "$IFACE" -n "host $TARGET_IP and tcp port 80" -w "$PCAP" &
TCPDUMP_PID=$!
echo "Waiting for capture to actually start (verifying, not just sleeping)..."
for i in $(seq 1 20); do
    if [ -f "$PCAP" ] && kill -0 "$TCPDUMP_PID" 2>/dev/null; then
        echo "Capture confirmed running (pid $TCPDUMP_PID)."
        break
    fi
    sleep 0.2
done
curl -s -o /dev/null --resolve "example.com:80:$TARGET_IP" http://example.com
sleep 1
sudo kill $TCPDUMP_PID 2>/dev/null
wait $TCPDUMP_PID 2>/dev/null
echo ""
echo "=== READING CAPTURE ==="
sudo tcpdump -r "$PCAP" -n
echo ""
echo "[READ THIS] Identify each flag combination above:"
echo "  [S]   = SYN       - client requests connection"
echo "  [S.]  = SYN+ACK   - server confirms, sends own SYN"
echo "  [.]   = ACK       - client confirms, handshake complete"
echo "  [P.]  = PUSH+ACK  - actual data (GET request / HTTP response)"
echo "  [F.]  = FIN+ACK   - graceful connection close"
echo ""
echo "[VERIFY] seq/ack math: SYN's seq + 1 should equal SYN-ACK's ack"
