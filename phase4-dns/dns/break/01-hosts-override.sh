#!/bin/bash
# Break 01: Poison /etc/hosts to silently break DNS resolution
set -euo pipefail

TARGET_DOMAIN="example.com"
WRONG_IP="192.168.100.100"
HOSTS_FILE="/etc/hosts"
BACKUP="${HOSTS_FILE}.bak.$(date +%s)"

# Abort if the domain already exists in /etc/hosts — prevents backing up
# an already-corrupted state (see postmortem/01-stale-manual-poison-corrupted-backup.md)
if grep -qE "[[:space:]]${TARGET_DOMAIN}([[:space:]]|$)" "$HOSTS_FILE"; then
    echo "[FAIL] '$TARGET_DOMAIN' already exists in $HOSTS_FILE. Aborting."
    echo "[FAIL] Clean up the existing entry first, or this backup would preserve a bad state."
    exit 1
fi

echo "[BREAK] Backing up $HOSTS_FILE to $BACKUP"
sudo cp "$HOSTS_FILE" "$BACKUP"

echo "[BREAK] Injecting wrong entry: $WRONG_IP $TARGET_DOMAIN"
echo "$WRONG_IP $TARGET_DOMAIN" | sudo tee -a "$HOSTS_FILE" > /dev/null

echo "[VERIFY] Resolution now shows:"
getent hosts "$TARGET_DOMAIN"
echo "[PROOF] If the IP above matches $WRONG_IP, /etc/hosts is silently overriding DNS."
echo "Backup saved at: $BACKUP — use fix/01-hosts-restore.sh to recover."
