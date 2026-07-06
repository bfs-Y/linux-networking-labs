#!/bin/bash
# Detect and fix poisoned ARP cache

GATEWAY="192.168.122.1"
IFACE=$(ip route | grep default | awk '{print $5}' | head -1)

echo "[CHECK] Detected interface: $IFACE"
echo "[CHECK] Current ARP entry for gateway:"
ip neigh show | grep $GATEWAY

echo "[FIX] Deleting any existing entry (including PERMANENT)..."
sudo ip neigh del $GATEWAY dev $IFACE 2>/dev/null

echo "[FIX] Re-resolving gateway MAC via ping..."
ping -c 1 $GATEWAY > /dev/null 2>&1

echo "[FIX] Verified:"
ip neigh show | grep $GATEWAY
