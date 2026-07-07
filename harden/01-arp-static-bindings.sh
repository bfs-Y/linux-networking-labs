#!/bin/bash
# Harden 01: Static ARP bindings — prevents ARP cache poisoning for known hosts
set -euo pipefail

GATEWAY_IP="192.168.122.1"
GATEWAY_MAC=$(ip neigh show "$GATEWAY_IP" | awk '{print $5}')

if [ -z "$GATEWAY_MAC" ]; then
  echo "[FAIL] Could not resolve gateway MAC. Ping the gateway first, then re-run."
  exit 1
fi

echo "[HARDEN] Binding $GATEWAY_IP permanently to $GATEWAY_MAC"
sudo ip neigh replace "$GATEWAY_IP" lladdr "$GATEWAY_MAC" nud permanent dev enp1s0

echo "[VERIFY] Static binding installed:"
ip neigh show "$GATEWAY_IP"
echo "[NOTE] This entry resists standard ARP poisoning replies from other hosts on the network."
echo "[NOTE] Limitation: does NOT protect against a local privileged process directly overwriting the entry (ip neigh replace as root)."
echo "[NOTE] Limitation: static entries don't scale — this hardens ONE critical host (gateway), not the whole subnet."
