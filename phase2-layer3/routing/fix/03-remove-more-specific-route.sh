#!/usr/bin/env bash
# Fix: remove the injected /32 route, restoring direct connected-route
# delivery for the affected host.
set -euo pipefail

TARGET_IP="192.168.122.207"
GATEWAY="192.168.122.1"

echo "Host check: $(hostname)"
echo "--- Route before fix ---"
ip route get "${TARGET_IP}"

echo "--- Removing the more-specific /32 route ---"
sudo ip route del "${TARGET_IP}/32" via "${GATEWAY}"

echo "--- Route after fix (should be direct again, no 'via') ---"
ip route get "${TARGET_IP}"
