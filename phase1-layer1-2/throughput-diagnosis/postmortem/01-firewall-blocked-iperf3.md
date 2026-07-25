Date: 2026-07-22
Lab: Phase 1 (Layer 1/2) - ethtool/NIC diagnosis, VM-to-VM throughput investigation
Hosts: training-vm (Ubuntu 24.04, 192.168.122.227), centos9 (CentOS Stream 9, 192.168.122.207)

Symptom (verbatim command and output):
Reported: training-vm (Ubuntu 24.04) throughput "terrible," file
transfers taking minutes instead of seconds. No error messages, no
dmesg output cited.

$ iperf3 -c 192.168.122.207
(run from training-vm, Ubuntu 24.04)
iperf3: error - unable to connect to server - server may have stopped
running or use a different port, firewall issue, etc.: No route to host

Root cause: centos9's (CentOS Stream 9) firewalld public zone had no
rule permitting inbound TCP port 5201, so the first iperf3 connection
attempt from training-vm (Ubuntu 24.04) was rejected by the firewall -
presenting as "No route to host" on the client rather than a
throughput problem.

Evidence:
- ip link show / ip -s link show on enp1s0 (training-vm, Ubuntu 24.04
  guest interface) and vnet0 (hypervisor-side tap device, host:
  ibnb-Latitude-E7240): link UP, LOWER_UP, zero errors, zero drops on
  both sides - ruled out Layer 1/2 fault.
- ethtool enp1s0 (training-vm, Ubuntu 24.04): all physical-layer
  fields (Speed, Duplex, link modes) reported Unknown/Not reported -
  confirmed enp1s0 is a virtio virtual NIC with no real PHY, making
  ethtool's speed/duplex diagnosis inapplicable to this host.
- sudo ufw status verbose (training-vm, Ubuntu 24.04): default allow
  (outgoing) - ruled out client-side outbound block.
- sudo firewall-cmd --list-all (centos9, CentOS Stream 9), fresh
  check: ports: (empty) - confirmed 5201/tcp was not permitted at
  time of failure.
- sudo firewall-cmd --permanent --add-port=5201/tcp + --reload on
  centos9, then --list-all again: ports: 5201/tcp, confirmed
  persistent.
- iperf3 -c 192.168.122.207 from training-vm (Ubuntu 24.04) after
  fix: 4.24-4.26 Gbits/sec sustained, 1 retransmit over ~5GB -
  healthy throughput for a virtio bridged link, not "terrible."

What changed vs what stayed the same:
Changed: centos9 (CentOS Stream 9) firewalld public zone gained a
permanent rule for 5201/tcp.
Stayed the same: training-vm (Ubuntu 24.04) ufw rules, ARP/neighbor
tables (already clean from prior lab), interface configs on both
VMs, routing, hypervisor-side bridge/tap setup.

Fix applied (on centos9, CentOS Stream 9):
sudo firewall-cmd --permanent --add-port=5201/tcp
sudo firewall-cmd --reload
Verified with firewall-cmd --list-all showing 5201/tcp persisted.

Automated or permanent version of the fix:
Add iperf3's port (or any lab-required service port) to centos9's
(CentOS Stream 9) firewalld config as part of VM provisioning/rebuild
scripts, so it isn't a manual step re-discovered under pressure each
time. N/A further - this was a one-time config gap, not a recurring
class of fault requiring monitoring.

Detection gap:
The original complaint ("throughput terrible" on training-vm, Ubuntu
24.04) was never independently measured before starting diagnosis -
no baseline iperf3 run, no transfer timing captured. This led to real
time spent checking ethtool/link-layer fields on training-vm that
were ultimately irrelevant, before the actual fault (a connectivity-
layer firewall block on centos9, not a throughput issue) was found.
A confirmed measurement should be the first evidence gathered for any
"it's slow" report, before assuming which layer or which host is
responsible - a hard failure and degraded performance are different
problems requiring different diagnostic paths.
