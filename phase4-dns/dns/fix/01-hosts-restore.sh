#!/bin/bash
# Fix 01: Restore /etc/hosts from the most recent backup
# Hardened after postmortem/01-stale-manual-poison-corrupted-backup.md:
# Known limitation: this check only detects the exact known-bad IP+domain
# pair from this incident, not general corruption. A future improvement
# would validate backup structure/syntax generally, not pattern-match a
# single known bad entry.
# "most recent backup" is not the same as "known-good backup" - a backup
# file itself could still contain the poisoned entry if it predates the
# break/ script's precondition check, or if /etc/hosts was manually
# touched between cycles. Verify the backup's content before trusting it.
set -euo pipefail

TARGET_DOMAIN="example.com"
KNOWN_BAD_IP="192.168.100.100"

LATEST_BACKUP=$(ls -t /etc/hosts.bak.* 2>/dev/null | head -n1)

if [ -z "$LATEST_BACKUP" ]; then
  echo "[FAIL] No backup found. Did you run break/01-hosts-override.sh first?"
  exit 1
fi

echo "[CHECK] Verifying backup content before trusting it: $LATEST_BACKUP"
if grep -qE "^${KNOWN_BAD_IP}[[:space:]]+${TARGET_DOMAIN}([[:space:]]|$)" "$LATEST_BACKUP"; then
  echo "[FAIL] Backup itself contains the known-bad entry ($KNOWN_BAD_IP $TARGET_DOMAIN)."
  echo "[FAIL] Restoring from this backup would reintroduce the poisoning it's meant to fix."
  echo "[FAIL] Manual cleanup required - do not blindly restore. Inspect: $LATEST_BACKUP"
  exit 1
fi

echo "[FIX] Backup looks clean. Restoring /etc/hosts from $LATEST_BACKUP"
sudo cp "$LATEST_BACKUP" /etc/hosts

echo "[VERIFY] Resolution now shows:"
getent ahosts "$TARGET_DOMAIN"
echo "[PROOF] If this no longer shows $KNOWN_BAD_IP, the poisoned entry is gone."
