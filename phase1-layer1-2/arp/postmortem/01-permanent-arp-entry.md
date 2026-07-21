Date: 2026-07-21
Lab: Phase 1 (Layer 1/2) — ARP: PERMANENT stale/incorrect entry

Symptom (verbatim command and output):
$ ping -c 2 192.168.122.207
PING 192.168.122.207 (192.168.122.207) 56(84) bytes of data.
--- 192.168.122.207 ping statistics ---
2 packets transmitted, 0 received, 100% packet loss, time 1031ms
(Silent timeout — no "Destination Host Unreachable," unlike a host
with no ARP entry at all.)

Root cause: A PERMANENT neighbor entry for 192.168.122.207 held a
fake MAC (00:11:22:33:44:55), so the kernel skipped ARP resolution
entirely and sent frames to a MAC no device owns, producing silent
timeouts instead of a fast ARP-failure error.

Evidence:
$ ip neigh show 192.168.122.207
192.168.122.207 dev enp1s0 lladdr 00:11:22:33:44:55 PERMANENT
— confirms kernel held a cached, non-aging, incorrect mapping.
Injected via phase1-layer1-2/arp/break/01-stale-arp-entry.sh
(sudo ip neigh replace ... nud permanent).

What changed vs what stayed the same:
Changed: neighbor table entry for 192.168.122.207, forced to
PERMANENT with a fake lladdr.
Stayed the same: interface state, IP config, routing table, all
other neighbor entries, firewall rules.

Fix applied:
$ sudo ip neigh del 192.168.122.207 dev enp1s0
Verified with ip neigh show 192.168.122.207 — empty output, entry
fully removed, kernel returned to normal ARP-on-demand state.

Automated or permanent version of the fix:
N/A for this lab (fault was intentionally injected for training).
In production: a monitoring check that flags any neighbor entry in
PERMANENT state that wasn't deliberately configured (e.g. periodic
`ip -j neigh show` parsed for nud PERMANENT on unexpected IPs) would
catch this class of fault, since PERMANENT entries never self-heal
and silent timeouts otherwise look identical to a dead host.

Detection gap:
Ping alone gave no distinguishing signal between "host down, no ARP
entry" and "PERMANENT entry with wrong MAC" — both show as timeout/
loss. Only ip neigh show exposed the actual state. Future Layer 2
connectivity checks should include ip neigh show as a standard step
before trusting ping's failure mode, since a fast ARP-unreachable
error and a silent black-hole timeout mean very different things
operationally.
