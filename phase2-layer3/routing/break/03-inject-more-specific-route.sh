#!/usr/bin/env bash
# Break: inject a /32 route more specific than an existing connected
# route, forcing one host's traffic through an unexpected path (the
# gateway) while everything else on the same subnet is unaffected.
# Demonstrates longest-prefix-match route selection.
set -euo pipefail

TARGET_IP="192.168.122.207"
GATEWAY="192.168.122.1"

echo "Host check: $(hostname)"
echo "--- Baseline route (before) ---"
ip route get "${TARGET_IP}"

echo "--- Injecting more-specific /32 route via gateway ---"
sudo ip route add "${TARGET_IP}/32" via "${GATEWAY}"

echo "--- Route after injection (should now show 'via ${GATEWAY}') ---"
ip route get "${TARGET_IP}"

echo ""
echo "Symptom: ${TARGET_IP} now routes via the gateway instead of the"
echo "direct connected path, even though the broader /24 route is still"
echo "present. Diagnose with: ip route (look for an unexpected /32),"
echo "then fix with fix/03-remove-more-specific-route.sh"
