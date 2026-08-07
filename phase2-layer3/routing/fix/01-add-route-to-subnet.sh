#!/usr/bin/env bash
# Fix: add a static route to 10.50.0.0/28 via ubuntulab, restoring
# reachability to a subnet the local routing table didn't know about.
# Run inside centos9 (CentOS Stream 9), NOT ubuntulab or the hypervisor.
set -euo pipefail
NETWORK="10.50.0.0/28"
VIA="192.168.122.226"
echo "Host check: $(hostname)"
echo "Adding route: ${NETWORK} via ${VIA}..."
sudo ip route add "${NETWORK}" via "${VIA}"
echo "Verifying:"
ip route show "${NETWORK}"
echo "Fix applied. Confirm with:"
echo "  ping -c 2 10.50.0.1"
echo "  (should now succeed - 0% loss)"
