Date: 2026-07-29
Lab: Phase 1 (Layer 1/2) - ARP: gratuitous ARP behavior and its limits

Symptom (verbatim command and output):
Scenario: verify that gratuitous ARP correctly updates a peer's cache
after a simulated failover (virtual IP moving between hosts), without
waiting for natural cache expiry.

Root cause: N/A (mechanism validation, not a fault investigation).
Gratuitous ARP's effectiveness depends entirely on the target entry's
existing state - it updates existing DYNAMIC entries correctly, but
does NOT create new entries where none exist (per arp_accept sysctl),
and does NOT update PERMANENT entries at all, by design.

Evidence:

Case 1 - no prior entry exists:
$ ip neigh show 192.168.122.227   # on centos9, before any test
(empty)
$ sudo arping -U -I enp1s0 -c 3 192.168.122.227   # from ubuntulab
Sent 3 probes, received 0 responses (expected - announcement, not query)
$ tcpdump -i enp1s0 -n arp   # on ubuntulab, confirms real packets sent:
  "ARP, Request who-has 192.168.122.227 tell 192.168.122.227" x3
$ ip neigh show 192.168.122.227   # on centos9, after
(still empty)
$ sysctl net.ipv4.conf.enp1s0.arp_accept
net.ipv4.conf.enp1s0.arp_accept = 0
Confirms: with arp_accept=0, a host will not create a new entry from
an unsolicited announcement alone - it must resolve the address itself
first (e.g. via ping) before gratuitous ARP has anything to update.

Case 2 - existing entry is PERMANENT:
$ ping -c 2 192.168.122.227 && ip neigh show 192.168.122.227   # centos9
... REACHABLE, real MAC (52:54:00:60:ac:85)
$ sudo ip neigh replace 192.168.122.227 lladdr 00:11:22:33:44:99 dev enp1s0
(no nud flag specified)
$ ip neigh show 192.168.122.227
... PERMANENT   <- ip neigh replace defaults to PERMANENT when no nud
                    state is explicitly given
$ sudo arping -U -I enp1s0 -c 3 192.168.122.227   # from ubuntulab
$ ip neigh show 192.168.122.227   # centos9, after
... still 00:11:22:33:44:99, still PERMANENT
Confirms: PERMANENT entries are immune to gratuitous ARP updates, same
as they are immune to normal aging/reachability probing - by design.

Case 3 - existing entry is DYNAMIC/mutable (real test):
$ sudo ip neigh replace 192.168.122.227 lladdr 00:11:22:33:44:99 nud reachable dev enp1s0
$ ip neigh show 192.168.122.227
... 00:11:22:33:44:99, REACHABLE (explicitly non-permanent this time)
$ sudo arping -U -I enp1s0 -c 3 192.168.122.227   # from ubuntulab
$ ip neigh show 192.168.122.227   # centos9, after
... 52:54:00:60:ac:85, STALE
Confirms: gratuitous ARP correctly updated the MAC to the real value.
Landed as STALE, not REACHABLE, because the announcement itself
involves no reply/round-trip confirmation - same self-healing pattern
as any STALE entry, will reconfirm on next real traffic exchange.

What changed vs what stayed the same:
Changed: centos9's neighbor entry for 192.168.122.227, deliberately
manipulated through three states (empty, PERMANENT-wrong, DYNAMIC-wrong)
to test each condition. Final state left as STALE with the correct MAC.
Stayed the same: no interface config, firewall, or routing was touched
on either host.

Fix applied:
N/A - this was a mechanism validation, not an incident. Final state
(correct MAC, STALE) is expected and healthy.

Automated or permanent version of the fix:
N/A. Operational takeaway for any real failover automation (VRRP/
keepalived-style): gratuitous ARP alone cannot be relied on to correct
every peer's cache unconditionally. Any host with arp_accept=0 and no
prior entry for the VIP, or any host with a PERMANENT static entry for
the VIP, will NOT update from a gratuitous ARP alone and may need a
separate detection/remediation path (e.g. periodic reachability checks
independent of ARP cache state).

Detection gap: N/A for this lab - the investigation was deliberately
structured to surface all three cases (no entry, PERMANENT, DYNAMIC)
rather than discover a gap after the fact.
