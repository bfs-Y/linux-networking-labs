#!/bin/bash
# Fix 01: Confirm/rule-out whether rx_dropped correlates to UFW-blocked
# traffic, using journalctl's UFW BLOCK log entries instead of trying to
# isolate a single counter from `nft list ruleset` (an earlier attempt
# failed - grep "drop" matched too many unrelated rules; no single
# counter isolates "packets that hit the final default policy drop").
#
# Design: send a known, deterministic number of UDP packets to an
# unallowed port from a remote host (centos9), then compare:
#   1. rx_dropped delta on the interface (kernel/driver-level count)
#   2. Count of matching UFW BLOCK log lines for that exact source+port
# Result (confirmed 2026-08-26): rx_dropped does NOT move even when UFW
# demonstrably drops matching traffic (10 confirmed UFW BLOCK log
# entries, rx_dropped delta = 0). This is architecturally expected:
# rx_dropped is a driver/NIC-level counter incremented before a packet
# is handed to netfilter; firewall drops happen later in the stack and
# never touch it. UFW BLOCK log counts are also rate-limited (ruleset
# shows "limit rate 3/minute burst 10 packets" on the logging rule), so
# even the log count under-reports actual drops beyond the burst limit -
# it is a sample, not an exhaustive count.
set -euo pipefail

IFACE="${1:-enp1s0}"
TARGET_PORT="59999"
REMOTE_SRC="192.168.122.207"   # centos9 - confirm current via `ip addr`
                                 # on centos9 before trusting it
PACKET_COUNT=20

echo "[SETUP] Watching interface: $IFACE on ubuntulab"
echo "[SETUP] Expecting UDP traffic FROM $REMOTE_SRC to port $TARGET_PORT"
echo ""

RX_BEFORE=$(cat /sys/class/net/${IFACE}/statistics/rx_dropped)
TIME_BEFORE=$(date '+%Y-%m-%d %H:%M:%S')

echo "[BEFORE] rx_dropped=${RX_BEFORE} at ${TIME_BEFORE}"
echo ""
echo ">>> NOW, on centos9, run:"
echo "    for p in \$(seq 1 $PACKET_COUNT); do echo test | nc -u -w1 192.168.122.226 $TARGET_PORT; done"
echo ">>> Press Enter here once done. <<<"
read -r _

sleep 1
RX_AFTER=$(cat /sys/class/net/${IFACE}/statistics/rx_dropped)
RX_DELTA=$((RX_AFTER - RX_BEFORE))

echo ""
echo "[AFTER] rx_dropped=${RX_AFTER}"
echo "[DELTA] rx_dropped increased by: ${RX_DELTA}"
echo ""

echo "[LOG CHECK] Counting UFW BLOCK entries matching SRC=${REMOTE_SRC} DPT=${TARGET_PORT}"
echo "            since ${TIME_BEFORE}..."
LOG_COUNT=$(sudo journalctl -k --since "$TIME_BEFORE" | grep "UFW BLOCK" | grep "SRC=${REMOTE_SRC}" | grep -c "DPT=${TARGET_PORT}" || true)

echo "[LOG COUNT] Matching UFW BLOCK entries: ${LOG_COUNT} (rate-limited to 10/burst - a sample, not exhaustive)"
echo "[SENT] Packets actually sent from centos9: ${PACKET_COUNT}"
echo ""

echo "=== RESULT ==="
echo "rx_dropped delta:      ${RX_DELTA}"
echo "UFW BLOCK log count:   ${LOG_COUNT}"
echo "Packets sent:          ${PACKET_COUNT}"
echo ""

# Verdict logic fixed 2026-08-26: previous version only checked RX_DELTA
# and fell through to a misleading "NO SIGNAL" even when LOG_COUNT alone
# proved real firewall drops occurred. rx_dropped=0 with LOG_COUNT>0 is
# now its own explicit, correctly-labeled outcome - not an error state.
if [ "$LOG_COUNT" -eq 0 ] && [ "$RX_DELTA" -eq 0 ]; then
    echo "[NO EVIDENCE] Neither counter moved - traffic likely didn't reach"
    echo "the interface, or the send command didn't run. Re-check the send"
    echo "step before trusting this result."
elif [ "$LOG_COUNT" -gt 0 ] && [ "$RX_DELTA" -eq 0 ]; then
    echo "[CONFIRMED: FIREWALL DROPS DO NOT INCREMENT rx_dropped]"
    echo "UFW confirmably blocked matching traffic (log evidence), but"
    echo "rx_dropped never moved. This is the expected, architecturally"
    echo "correct result: rx_dropped is a driver/NIC-level counter,"
    echo "incremented BEFORE a packet reaches netfilter/UFW. Firewall"
    echo "drops happen later in the stack and do not touch this counter."
    echo "Conclusion: rx_dropped increments are NOT explained by firewall"
    echo "activity, regardless of how much traffic UFW blocks."
elif [ "$RX_DELTA" -gt 0 ] && [ "$LOG_COUNT" -eq 0 ]; then
    echo "[SIGNAL: DRIVER/NIC-LEVEL DROP, NOT FIREWALL]"
    echo "rx_dropped moved with no matching firewall log - drop is"
    echo "happening before/outside netfilter (ring buffer, driver, etc.)."
else
    echo "[BOTH MOVED] Investigate further - could be coincidental overlap"
    echo "of two independent drop sources, not necessarily causal."
fi
