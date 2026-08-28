#!/bin/bash
# Fix 03: Restore DNS resolution after break/03-dead-resolver.sh redirected
# it to an unreachable server.
#
# NOTE: `resolvectl revert <iface>` does NOT reliably restore DNS state
# on this system - testing showed it leaves the interface with
# "Current Scopes: none" and no DNS server at all, a different broken
# state, not a fix. The proven recovery is cycling the NetworkManager
# connection, which forces a fresh DHCP re-fetch of DNS config.
set -euo pipefail

IFACE="${1:-enp1s0}"
CONNECTION="netplan-${IFACE}"

echo "[FIX] Cycling connection $CONNECTION to force fresh DHCP DNS config..."
sudo nmcli connection down "$CONNECTION"
sudo nmcli connection up "$CONNECTION"

echo "[VERIFY] Current DNS server for $IFACE:"
resolvectl status "$IFACE" | grep "Current DNS Server"

echo "[FLUSH] Clearing any stale cached lookups from the dead-resolver test:"
sudo resolvectl flush-caches

echo "[PROOF] DNS server above should show the real gateway (e.g. 192.168.122.1),"
echo "not the dead test IP, and not be empty/none."
