#!/bin/bash
# Fix 02: Restore /etc/nsswitch.conf from the most recent backup taken
# by break/02-nsswitch-reorder.sh
set -euo pipefail

LATEST_BACKUP=$(ls -t /etc/nsswitch.conf.bak.* 2>/dev/null | head -n1)

if [ -z "$LATEST_BACKUP" ]; then
  echo "[FAIL] No backup found. Did you run break/02-nsswitch-reorder.sh first?"
  exit 1
fi

echo "[FIX] Restoring /etc/nsswitch.conf from $LATEST_BACKUP"
sudo cp "$LATEST_BACKUP" /etc/nsswitch.conf

echo "[VERIFY] Current hosts line:"
grep "^hosts:" /etc/nsswitch.conf

echo "[FLUSH] Clearing resolver cache to ensure fresh state:"
sudo resolvectl flush-caches

echo "[PROOF] hosts: line should now show 'files ... dns' (original order),"
echo "not 'dns files' (the reordered state)."
