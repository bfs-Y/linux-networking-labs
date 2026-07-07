#!/bin/bash
# Break 06b: NAT/MASQUERADE rule removed — container traffic leaks real IP
set -euo pipefail

echo "[BREAK] Flushing NAT table to simulate MASQUERADE rule loss..."
sudo iptables -t nat -F POSTROUTING

echo "[BREAK] NAT rules flushed. Container outbound traffic will now leak its"
echo "internal IP instead of being rewritten to the host's IP."
echo "Run verify/06-nat-verify.sh now — the proof output should show the"
echo "CONTAINER IP as source, not the host's, confirming NAT is broken."
