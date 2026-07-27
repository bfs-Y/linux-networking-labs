#!/usr/bin/env bash
# Break: flood ubuntulab's enp1s0 with a high-bitrate UDP stream via iperf3,
# to genuinely stress the receive path and attempt to produce real
# rx_dropped increments (UDP has no flow control, unlike TCP).
# PREREQUISITE: iperf3 -s must already be running on ubuntulab before
# this script is executed.
# Run inside centos9 (CentOS Stream 9), NOT ubuntulab or the hypervisor.
set -euo pipefail
TARGET_IP="192.168.122.227"   # ubuntulab
echo "Host check: $(hostname)"
echo "Starting UDP flood to ${TARGET_IP} - 1Gbit/s target, 10 seconds..."
iperf3 -c "${TARGET_IP}" -u -b 1G -t 10
echo "Flood complete. Check ubuntulab's rx_dropped before/after this run:"
echo "  cat /sys/class/net/enp1s0/statistics/rx_dropped"
