#!/bin/bash
# Break 04: Start an unauthorized listener on port 8080
# Effect: simulates a rogue process binding to an unexpected port
# Recovery: fix/04-kill-rogue-port.sh

PORT=8080

echo "[BREAK] Starting rogue listener on port $PORT..."
nc -lk "$PORT" &
disown
echo "[VERIFY] Listener confirmed:"
sudo ss -tulnp | grep "$PORT"
