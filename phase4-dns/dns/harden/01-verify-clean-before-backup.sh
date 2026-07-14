#!/bin/bash
# Harden: verify /etc/hosts is clean BEFORE backing it up, so a stale
# manual test artifact never gets baked into a "known good" backup.
# See postmortem/01-stale-manual-poison-corrupted-backup.md -- this
# script formalizes that postmortem's prevention recommendation.
set -euo pipefail

TARGET_DOMAIN="example.com"
HOSTS_FILE="/etc/hosts"

echo "Host check: $(hostname)"
echo "Verifying ${HOSTS_FILE} is clean before any backup is trusted..."

if grep -qE "[[:space:]]${TARGET_DOMAIN}([[:space:]]|$)" "$HOSTS_FILE"; then
    echo "[FAIL] '${TARGET_DOMAIN}' already present in ${HOSTS_FILE}."
    echo "[FAIL] Refusing to treat any existing backup as trustworthy."
    echo "[FAIL] Manually clean this entry before running break/fix scripts."
    exit 1
fi

echo "[OK] ${HOSTS_FILE} is clean. Safe to proceed with break/01-hosts-override.sh."
