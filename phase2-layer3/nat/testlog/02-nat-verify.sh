#!/usr/bin/env bash
# Testlog: confirm NAT/MASQUERADE is actually working, using a direct
# connectivity check instead of a fragile packet-capture timing race.
set -euo pipefail

CONTAINER="nat-test"

echo "Host check: $(hostname)"

echo "[PRE-CHECK] Confirming container is running..."
if ! sudo docker ps --format '{{.Names}}' | grep -qx "$CONTAINER"; then
  echo "[FAIL] Container '$CONTAINER' is not running."
  echo "Fix: sudo docker rm -f $CONTAINER 2>/dev/null; sudo docker run -d --name $CONTAINER alpine sleep 3600"
  exit 1
fi
echo "[OK] Container is running."

echo "[VERIFY] Attempting real HTTP request from inside the container (wget, alpine default)..."
if sudo docker exec "$CONTAINER" wget -q -O /dev/null --timeout=5 http://example.com; then
  echo "[PASS] NAT is working — container successfully reached the internet."
  exit 0
else
  echo "[FAIL] NAT is NOT working — container could not complete an HTTP request."
  exit 1
fi
