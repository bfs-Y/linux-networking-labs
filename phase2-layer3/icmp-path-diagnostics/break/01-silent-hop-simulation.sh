#!/usr/bin/env bash
# Break: block outbound ICMP time-exceeded replies, simulating a
# router that appears "silent" to traceroute/mtr (shows "* * *" or
# high loss%) while still forwarding real traffic normally. This
# demonstrates the difference between an unresponsive hop and an
# actually broken one - the lesson from this session's real traceroute
# investigation (hop 5, 10.206.179.195, showed 95% loss in mtr but
# was fully healthy when tested directly).
# Run inside ubuntulab (Ubuntu 24.04), NOT centos9 or the hypervisor.
set -euo pipefail
echo "Host check: $(hostname)"
echo "Current ICMP rules on OUTPUT:"
sudo iptables -L OUTPUT -n -v | grep -i icmp || echo "(none currently)"
echo "Blocking outbound ICMP time-exceeded replies..."
sudo iptables -I OUTPUT -p icmp --icmp-type time-exceeded -j DROP
echo "Fault reproduced. This machine will now appear silent/unresponsive"
echo "to traceroute or mtr probes passing THROUGH it as an intermediate"
echo "hop, while continuing to forward real traffic normally."
echo "Confirm real traffic still works:"
echo "  ping -c 4 8.8.8.8"
echo "  (should succeed normally - this rule only blocks time-exceeded"
echo "   replies, not general ICMP or forwarded traffic)"
echo "Fix: ./phase2-layer3/icmp-path-diagnostics/fix/01-restore-hop-responses.sh"
