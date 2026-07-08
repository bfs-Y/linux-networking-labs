#!/bin/bash
# Harden 03: ARP change monitor — detects MAC/IP mapping changes in real time
set -euo pipefail

LOGFILE="/var/log/arp-monitor.log"
echo "[HARDEN] Monitoring ARP table for changes. Logging to $LOGFILE. Ctrl+C to stop."

PREV=$(ip neigh show)
while true; do
  sleep 2
  CURR=$(ip neigh show)
  if [ "$PREV" != "$CURR" ]; then
    echo "$(date): ARP table changed" | sudo tee -a "$LOGFILE"
    diff <(echo "$PREV") <(echo "$CURR") | sudo tee -a "$LOGFILE"
  fi
  PREV="$CURR"
done
