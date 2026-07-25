#!/usr/bin/env bash
# Break: remove the firewalld rule permitting inbound TCP 5201, simulating
# a service port that was never opened (or got closed) on the server side.
# Surgical removal only - does not touch other rules (SSH, cockpit, etc.)
# Run inside centos9 (CentOS Stream 9), NOT training-vm or the hypervisor.
set -euo pipefail
PORT="5201/tcp"
echo "Host check: $(hostname)"
echo "Current firewalld state for ${PORT}:"
sudo firewall-cmd --list-ports || true
echo "Removing ${PORT} from permanent config..."
sudo firewall-cmd --permanent --remove-port="${PORT}"
sudo firewall-cmd --reload
echo "Fault reproduced. Confirm with:"
echo "  sudo firewall-cmd --list-all"
echo "  (should NOT show ${PORT} under ports:)"
echo "  from training-vm: iperf3 -c 192.168.122.207   # should fail: No route to host"
