#!/bin/bash
# Break 02: Reorder /etc/nsswitch.conf to put dns before files, then
# measure the real latency cost of a lookup that should be local
# (hostname / localhost) - proving the reasoning from lab-notes/02:
# NSS defaults to "continue" on notfound/unavail/tryagain, so reordering
# rarely breaks resolution outright, but it may add latency to lookups
# that used to be free (a disk read) if a real network query happens.
#
# v2 (2026-08-27): first version confounded the measurement with cache
# state - "before" was a cold lookup, "after" reused a warm cache, so
# the timing difference measured caching, not resolution order. Fixed
# by flushing systemd-resolved's cache before every timed measurement,
# so both conditions start from the same cold state.
set -euo pipefail

NSSWITCH="/etc/nsswitch.conf"
BACKUP="${NSSWITCH}.bak.$(date +%s)"
TARGET="$(hostname)"

echo "[BREAK] Backing up $NSSWITCH to $BACKUP"
sudo cp "$NSSWITCH" "$BACKUP"

echo "[BASELINE] Current hosts line:"
grep "^hosts:" "$NSSWITCH"

echo ""
echo "[FLUSH] Clearing resolver cache before baseline measurement..."
sudo resolvectl flush-caches

echo "[BASELINE] Timing lookup of local hostname ($TARGET) BEFORE reorder (cold):"
time getent hosts "$TARGET"

echo ""
echo "[BREAK] Reordering hosts line: files first -> dns first"
sudo sed -i 's/^hosts:.*/hosts:          dns files mdns4_minimal [NOTFOUND=return]/' "$NSSWITCH"

echo "[BREAK] New hosts line:"
grep "^hosts:" "$NSSWITCH"

echo ""
echo "[FLUSH] Clearing resolver cache before AFTER measurement..."
sudo resolvectl flush-caches

echo "[TEST] Timing lookup of local hostname ($TARGET) AFTER reorder (cold):"
time getent hosts "$TARGET"

echo ""
echo "[REPEAT] Running AFTER measurement again (still dns-first, cache now warm)"
echo "to confirm cache effect is separated from order effect:"
time getent hosts "$TARGET"

echo ""
echo "[PROOF] Compare the two COLD 'real' time values (BASELINE vs first AFTER)."
echo "Both started from a flushed cache, so any difference now reflects"
echo "resolution order, not caching. The REPEAT run shows what a warm"
echo "cache looks like regardless of order - for contrast only."
echo ""
echo "Backup saved at: $BACKUP - use fix/02-nsswitch-restore.sh to recover."
