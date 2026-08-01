Date: 2026-07-30
Lab: Phase 1 - NIC bonding (active-backup) setup and failover test

Symptom (verbatim command and output):
Wanted redundant network connectivity on ubuntulab (Ubuntu 24.04) -
if one NIC fails, traffic should keep flowing over the other without
interruption. Two interfaces available: enp1s0 (live SSH/management
path) and enp7s0 (isolated, no IP assigned).

Root cause: N/A - this was a build/test exercise, not a fault
investigation. One real intermediate issue was found and diagnosed
along the way: an early failover test showed connectivity loss that
was NOT caused by bonding itself, but by a stale ARP cache entry for
the gateway that predated the interface change.

Evidence:

Setup:
$ sudo modprobe bonding
$ lsmod | grep '^bonding'
  bonding 253952 0
$ sudo ip link add bond0 type bond mode active-backup
  (first attempt used default mode balance-rr - wrong for this goal,
  deleted and recreated with mode active-backup explicit)
$ sudo ip link set bond0 type bond miimon 100
  (miimon was 0 by default - link-failure detection would never have
  fired without setting a real polling interval)

First enslavement attempt (enp1s0) failed silently:
$ sudo ip link set enp1s0 master bond0
  (no error returned)
$ cat /proc/net/bonding/bond0
  Currently Active Slave: None   <- enslavement did not actually take
Root cause of the silent failure: enp1s0 still had its live IP
(192.168.122.227/24) directly assigned. Confirmed via ip addr show
enp1s0 before retrying.

Safe path taken instead - enslaved enp7s0 first (no IP, no risk):
$ sudo ip link set enp7s0 down && sudo ip link set enp7s0 master bond0
$ cat /proc/net/bonding/bond0
  Currently Active Slave: enp7s0   <- confirmed real success this time

Second slave (enp1s0) - required moving the live IP off the physical
interface and onto bond0 in a single chained command to minimize
disconnection risk:
$ sudo ip addr del 192.168.122.227/24 dev enp1s0 && \
  sudo ip link set enp1s0 down && \
  sudo ip link set enp1s0 master bond0 && \
  sudo ip link set bond0 up && \
  sudo ip addr add 192.168.122.227/24 dev bond0
SSH session survived without interruption. Verified with ip link show
master bond0 and /proc/net/bonding/bond0 - both slaves present.

Stale routes found and cleaned up after the IP move:
$ ip route
  duplicate 192.168.122.0/24 entries (one via bond0, one still via
  enp1s0 with metric 100), and default route still via enp1s0
$ sudo ip route del 192.168.122.0/24 dev enp1s0
$ sudo ip route del default dev enp1s0
$ sudo ip route add default via 192.168.122.1 dev bond0
Confirmed clean afterward - only bond0-based routes remained.

First failover test (misleading result due to stale ARP):
$ sudo ip link set enp7s0 down
$ ping -c 4 192.168.122.1
  100% packet loss, "Destination Host Unreachable"
Diagnosed with: ip neigh show 192.168.122.1
  showed FAILED entries on both enp1s0 and bond0 - stale ARP cache
  for the gateway, unrelated to the bonding mechanism itself. The
  bond's Currently Active Slave was still enp7s0 at this point (had
  not yet failed), so the ping failure was not even a bonding event.
Fixed by setting enp1s0 as primary slave and clearing stale ARP:
$ sudo ip link set bond0 type bond primary enp1s0
$ sudo ip neigh del 192.168.122.1 dev bond0
$ sudo ip neigh del 192.168.122.1 dev enp1s0
$ ping -c 4 192.168.122.1
  0% packet loss - confirmed clean after ARP cleared

Second, clean failover test (real proof):
$ sudo ip link set enp7s0 down
$ cat /proc/net/bonding/bond0
  Slave Interface: enp7s0, MII Status: down, Link Failure Count: 1
  Currently Active Slave: enp1s0 (unaffected, MII Status: up)
$ ping -c 4 192.168.122.1
  4 packets transmitted, 4 received, 0% packet loss
Confirms genuine active-backup failover: enp7s0 going down had zero
impact on connectivity because enp1s0 (primary, already active)
remained up throughout.

Recovery:
$ sudo ip link set enp7s0 up
  (MII Status took ~1 second to reflect UP again - bond driver polls
  on its 100ms miimon interval, not instantaneous)
Confirmed both slaves healthy afterward, enp1s0 still active/primary,
enp7s0 back on standby.

What changed vs what stayed the same:
Changed: enp1s0 and enp7s0 both enslaved to bond0; live IP and default
route moved from enp1s0 to bond0; bond0 set to active-backup mode with
enp1s0 as primary and miimon 100.
Stayed the same: gateway (192.168.122.1), overall subnet, other hosts
(centos9) unaffected throughout.

Fix applied: N/A - build/test exercise. The one real fix applied
mid-exercise was clearing the stale ARP cache entries that had
nothing to do with bonding but complicated the first failover test's
result.

Automated or permanent version of the fix:
N/A for the build itself. Operational takeaway: when testing failover
on a freshly-migrated interface, clear/verify ARP state for critical
peers (like the gateway) BEFORE running a failover test - otherwise a
stale cache entry can produce a false-negative result that looks like
a bonding failure but isn't.

Detection gap:
The first failover test's connectivity loss could have been
misattributed to a bonding malfunction if /proc/net/bonding/bond0
hadn't been checked directly - it showed the bond itself was fine
(enp7s0 still active, no failure recorded) while ping failed for an
unrelated reason. Always check the bond's own authoritative status
file before assuming a connectivity test result reflects the bonding
mechanism's actual behavior.
