#!/bin/bash
# Fix 04: Identify and kill rogue listener on a given port
# Pairs with: break/04-rogue-port.sh
# Usage: ./04-kill-rogue-port.sh <port>

PORT="${1:-8080}"

echo "[INVESTIGATE] Checking what's listening on port $PORT..."
LINE=$(sudo ss -tulnp | grep ":$PORT ")
echo "$LINE"

PID=$(echo "$LINE" | grep -oP 'pid=\K[0-9]+')

if [ -z "$PID" ]; then
  echo "[RESULT] Nothing listening on port $PORT. Nothing to fix."
  exit 0
fi

echo "[INVESTIGATE] Process details for PID $PID:"
ps -fp "$PID"

echo "[FIX] Killing PID $PID with SIGTERM..."
kill "$PID"
sleep 1

echo "[VERIFY] Port $PORT should now be clear:"
sudo ss -tulnp | grep ":$PORT " || echo "Confirmed clean — nothing listening on $PORT"
