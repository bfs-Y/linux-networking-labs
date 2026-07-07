#!/bin/bash
# Harden 02: arptables rate-limiting — blunts ARP flood/poisoning attempts
set -euo pipefail

if ! command -v arptables &>/dev/null; then
  echo "[FAIL] arptables not installed. Run: sudo apt install arptables"
  exit 1
fi

echo "[HARDEN] Rate-limiting inbound ARP replies to 5/sec, dropping excess"
sudo arptables -A INPUT --opcode Reply -m limit --limit 5/sec -j ACCEPT
sudo arptables -A INPUT --opcode Reply -j DROP

echo "[VERIFY] Current arptables ruleset:"
sudo arptables -L
echo "[NOTE] This mitigates flood-style ARP poisoning attempts, not a single crafted spoof."
