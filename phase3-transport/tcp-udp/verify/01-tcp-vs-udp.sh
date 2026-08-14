#!/bin/bash
# Topic 01 (TCP/IP): Prove the TCP vs UDP packet-count tradeoff with real captures
# Not destructive - a verification/comparison exercise, same evidence standard as every topic.
IFACE=$(ip route | grep default | awk '{print $5}' | head -1)

DNS_SERVER=$(resolvectl status 2>/dev/null | grep -A5 "$IFACE" | grep "Current DNS Server" | awk '{print $NF}')
if [ -z "$DNS_SERVER" ]; then
    echo "[WARN] Could not auto-detect upstream DNS server, defaulting to 192.168.122.1"
    DNS_SERVER="192.168.122.1"
fi

echo "=== UDP capture (DNS lookup) ==="
echo "[NOTE] Querying the upstream DNS server directly (@${DNS_SERVER}) on ${IFACE},"
echo "bypassing the local systemd-resolved stub (127.0.0.53), which otherwise keeps"
echo "the query on loopback and invisible to a capture on ${IFACE}."
sudo rm -f /tmp/udp-verify.pcap
sudo tcpdump -i "$IFACE" -n udp port 53 -w /tmp/udp-verify.pcap &
UDP_PID=$!
for i in $(seq 1 20); do
    [ -f /tmp/udp-verify.pcap ] && kill -0 "$UDP_PID" 2>/dev/null && break
    sleep 0.2
done
dig +short @"$DNS_SERVER" google.com > /dev/null
sleep 2
sleep 0.5
sudo kill -INT "$UDP_PID" 2>/dev/null
wait "$UDP_PID" 2>/dev/null
sudo tcpdump -r /tmp/udp-verify.pcap -n

echo ""
echo "=== TCP capture (HTTP request) ==="
sudo rm -f /tmp/tcp-verify.pcap
sudo tcpdump -i "$IFACE" -n tcp port 80 -w /tmp/tcp-verify.pcap &
TCP_PID=$!
for i in $(seq 1 20); do
    [ -f /tmp/tcp-verify.pcap ] && kill -0 "$TCP_PID" 2>/dev/null && break
    sleep 0.2
done
curl -s -o /dev/null http://example.com
sleep 0.5
sudo kill -INT "$TCP_PID" 2>/dev/null
wait "$TCP_PID" 2>/dev/null
sudo tcpdump -r /tmp/tcp-verify.pcap -n

echo ""
echo "[COMPARE] Count the packets in each section above."
echo "UDP: typically 2 packets (one question, one answer) - no handshake, no guarantee."
echo "TCP: typically 8-10+ packets for the same single request/response -"
echo "     3 to establish (SYN/SYN-ACK/ACK), separate acks for data, formal close (FIN)."
echo "This packet-count difference IS the literal cost of TCP's reliability guarantee."
