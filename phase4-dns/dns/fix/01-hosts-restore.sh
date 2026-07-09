#!/bin/bash
# Fix 01: Restore /etc/hosts from the most recent backup
set -euo pipefail

TARGET_DOMAIN="example.com"
LATEST_BACKUP=$(ls -t /etc/hosts.bak.* | head -n1)

if [ -z "$LATEST_BACKUP" ]; then
  echo "[FAIL] No backup found. Did you run break/01-hosts-override.sh first?"
  exit 1
fi

echo "[FIX] Restoring /etc/hosts from $LATEST_BACKUP"
sudo cp "$LATEST_BACKUP" /etc/hosts

echo "[VERIFY] Resolution now shows:"
getent hosts "$TARGET_DOMAIN"
echo "[PROOF] If this no longer shows 192.168.100.100, the poisoned entry is gone."
