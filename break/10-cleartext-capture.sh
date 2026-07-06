#!/bin/bash
# Break 10: Capture genuine plaintext HTTP traffic, proving what SSL stripping exposes
# This is the visible proof behind the SSL-stripping attack: no decryption needed,
# the actual request (and any credentials in a real login form) sits in plain text.

echo "[SETUP] Starting capture of plaintext HTTP traffic..."
sudo tcpdump -i enp1s0 -n -A tcp port 80 -w ~/http-cleartext.pcap -c 20 &
disown
sleep 1

echo "[TRIGGER] Requesting a real plain-HTTP-only site (neverssl.com)..."
curl -s -o /dev/null http://neverssl.com
sleep 2

echo "[VERIFY] Capture file:"
ls -lh ~/http-cleartext.pcap

echo ""
echo "[PROOF] Reading the raw capture for readable plaintext content:"
sudo tcpdump -r ~/http-cleartext.pcap -A -n | grep -A 5 "GET /"
