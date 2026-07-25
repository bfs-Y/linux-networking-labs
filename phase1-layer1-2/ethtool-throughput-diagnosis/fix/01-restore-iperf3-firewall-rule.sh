#!/usr/bin/env bash
# Fix: restore the firewalld rule permitting inbound TCP 5201, allowing
# iperf3 clients to connect to the server again.
# Surgical addition only - does not touch other rules (SSH, cockpit, etc.)
# Run inside centos9 (CentOS Stream 9), NOT training-vm or the hypervisor.
set -euo pipefail
PORT="5201/tcp"
echo "Host check: $(hostname)"
echo "Current firewalld state for ${PORT}:"
sudo firewall-cmd --list-ports || true
echo "Restoring ${PORT} in permanent config..."
sudo firewall-cmd --permanent --add-port="${PORT}"
sudo firewall-cmd --reload
echo "Verifying restored rule:"
sudo firewall-cmd --list-all
echo "Fix applied. Confirm ${PORT} appears under ports:"
echo "  from training-vm: iperf3 -c 192.168.122.207   # should succeed"
