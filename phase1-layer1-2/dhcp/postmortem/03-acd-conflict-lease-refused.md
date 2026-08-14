Date: 2026-08-13
Lab: Phase 1 - DHCP: real ACD (Address Conflict Detection) conflict, lease refused, interface lost its IPv4 address

Symptom (verbatim command and output):
While working on an unrelated Phase 3 task, enp1s0 on ubuntulab
(Ubuntu 24.04) was discovered to have NO IPv4 address at all:
$ ip addr show enp1s0
  (UP, LOWER_UP, only an inet6 link-local address - no inet line)
$ ip route
  (no default route at all - explains why $(ip route | grep default
  | awk '{print $5}') was returning empty in an unrelated script)
The active SSH session using 192.168.122.226 remained connected
throughout - an established TCP connection survived the interface
losing its address, though any NEW connection attempt would have
failed.

Root cause: NetworkManager's DHCP client repeatedly detected an
Address Conflict (ACD) when trying to lease 192.168.122.226 to
enp1s0, and correctly refused to apply the address rather than risk
a real duplicate-IP conflict on the network.

Evidence:
$ sudo journalctl -u NetworkManager --since "15 minutes ago"
  Repeated log lines: "dhcp4 (enp1s0): state changed new lease,
  address=192.168.122.226, acd conflict" - recurring every ~30-300
  seconds over roughly 10 minutes, each retry hitting the same
  conflict.
  Also: "unable to configure IPv4 route ... pref-src 192.168.122.226"
  - route configuration blocked as a direct consequence of the
  refused address.

Direct check for a live conflicting device:
$ arping -D -I enp1s0 -c 3 192.168.122.226
  Sent 3 probes, Received 0 response(s) - no device currently
  answering for that address. This means the conflict, whatever
  triggered it, was likely transient/stale by the time it was
  investigated - not an active, ongoing duplicate assignment.

Fix applied:
$ sudo nmcli device reapply enp1s0
  Did NOT resolve it - reapplying the existing (already-failed)
  connection config wasn't sufficient.
$ sudo nmcli device disconnect enp1s0
$ sudo nmcli device connect enp1s0
  This DID resolve it - a full disconnect/reconnect forced a fresh
  DHCP negotiation from scratch, rather than retrying against
  whatever state caused the original conflict.
$ ip addr show enp1s0
  inet 192.168.122.226/24 ... valid_lft 3599sec - fresh lease
  confirmed, full hour validity.
$ ip route
  Default route and local subnet route both restored, correctly
  showing metric 100 (DHCP-assigned routes carry an explicit metric,
  consistent with earlier findings this session).

What changed vs what stayed the same:
Changed: enp1s0 was disconnected and reconnected via NetworkManager,
triggering a fresh DHCP lease negotiation.
Stayed the same: the actual IP address obtained (192.168.122.226,
same as before) - the conflict cleared on its own between when it
was first logged and when it was investigated; the fix was really
about forcing NetworkManager to retry cleanly rather than resolving
a still-active external conflict.

Fix applied: nmcli device disconnect + connect on enp1s0, verified
with a fresh DHCP lease and restored routing table.

Automated or permanent version of the fix: N/A - root cause of the
original conflict trigger was never identified (arping showed no
active conflicting device by the time it was checked). If this
recurs, the next investigation should check journalctl at the exact
moment of conflict (not after the fact) and check ARP tables on other
hosts on the same network (e.g. centos9, the hypervisor itself) for
any stale entry pointing a different MAC at 192.168.122.226 - this
session's bonding work earlier created and deleted several interfaces
that may be worth reviewing as a possible source of a stale ARP/lease
artifact, though this was not confirmed.

Detection gap: The address loss was discovered indirectly, as a side
effect while debugging an unrelated script (IFACE variable coming up
empty) rather than through any direct monitoring of interface health.
A real environment would benefit from an active check (e.g. periodic
ip addr / systemd unit) alerting if a primary interface loses its
expected IPv4 address, rather than relying on it being noticed
incidentally through an unrelated symptom.
