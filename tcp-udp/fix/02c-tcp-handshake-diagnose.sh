#!/bin/bash
# Topic 2c (TCP/IP): Diagnose a TCP handshake failure
# Usage: ./02c-tcp-handshake-diagnose.sh <target-hostname>
# Isolates whether a connection failure is local/ISP-side or remote/destination-side

TARGET="${1:-neverssl.com}"
IFACE=$(ip route | grep default | awk '{print $5}' | head -1)
TARGET_IP=$(dig +short "$TARGET" | head -1)
BASELINE="example.com"
BASELINE_IP=$(dig +short "$BASELINE" | head -1)

echo "[DIAGNOSE] Target: $TARGET ($TARGET_IP)"
echo "[DIAGNOSE] Baseline (known-good): $BASELINE ($BASELINE_IP)"
echo ""

echo "=== STEP 1: Test baseline (known-good site) ==="
if curl -s -o /dev/null -w "%{http_code}" --max-time 5 "http://$BASELINE" | grep -q 200; then
    echo "[OK] Baseline reachable — local machine, VM, gateway, ISP, DNS all confirmed working."
else
    echo "[FAIL] Baseline unreachable — problem is on YOUR side (machine/VM/gateway/ISP/DNS)."
    echo "[STOP] Fix local connectivity before testing the target further."
    exit 1
fi

echo ""
echo "=== STEP 2: Test target ==="
if curl -s -o /dev/null -w "%{http_code}" --max-time 5 "http://$TARGET" | grep -q 200; then
    echo "[OK] Target reachable. No issue detected."
    exit 0
else
    echo "[FAIL] Target unreachable while baseline succeeded."
    echo "[CONCLUSION] Fault is isolated to the target server or a firewall in front of it."
fi

echo ""
echo "=== STEP 3: Capture the failed handshake ==="
sudo timeout 5 tcpdump -i "$IFACE" -n "host $TARGET_IP and tcp" -c 10 &
sleep 1
curl -s -o /dev/null --max-time 4 "http://$TARGET" 2>/dev/null
wait

echo ""
echo "=== STEP 4: Trace how far packets actually get ==="
traceroute -n "$TARGET_IP" 2>/dev/null | tail -15

echo ""
echo "[DIAGNOSIS COMPLETE]"
echo "If only SYN packets appear with no SYN-ACK: target is dropping/ignoring connections."
echo "If traceroute dies with * * * near the end: firewall or dead host near the destination."
