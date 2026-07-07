#!/bin/bash
# Topic 2 (TCP/IP): Prove the TCP vs UDP packet-count tradeoff with real captures
# Not destructive — a verification/comparison exercise, same evidence standard as every topic.

echo "=== UDP capture (DNS lookup) ==="
sudo timeout 3 tcpdump -i enp1s0 -n udp port 53 &
sleep 1
dig +short google.com > /dev/null
wait

echo ""
echo "=== TCP capture (HTTP request) ==="
sudo timeout 3 tcpdump -i enp1s0 -n tcp port 80 &
sleep 1
curl -s -o /dev/null http://example.com
wait

echo ""
echo "[COMPARE] Count the packets in each section above."
echo "UDP: typically 2 packets (one question, one answer) — no handshake, no guarantee."
echo "TCP: typically 8-10+ packets for the same single request/response —"
echo "     3 to establish (SYN/SYN-ACK/ACK), separate acks for data, formal close (FIN)."
echo "This packet-count difference IS the literal cost of TCP's reliability guarantee."
