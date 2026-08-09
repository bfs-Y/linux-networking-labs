#!/usr/bin/env bash
# Fix: remove the ICMP time-exceeded DROP rule, restoring normal
# traceroute/mtr hop responses.
# Run inside ubuntulab (Ubuntu 24.04), NOT centos9 or the hypervisor.
set -euo pipefail
echo "Host check: $(hostname)"
echo "Removing ICMP time-exceeded DROP rule..."
sudo iptables -D OUTPUT -p icmp --icmp-type time-exceeded -j DROP
echo "Verifying:"
sudo iptables -L OUTPUT -n -v | grep -i icmp || echo "Confirmed clean - no ICMP time-exceeded block remains"
echo "Fix applied."
