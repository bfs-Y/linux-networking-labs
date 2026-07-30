Date: 2026-07-30
Lab: Phase 1 - 802.1Q VLAN tagging verification

Symptom (verbatim command and output):
Set up a VLAN sub-interface (enp1s0.100) on ubuntulab (Ubuntu 24.04)
and needed to verify whether 802.1Q tagging was actually happening on
the wire, not just configured correctly.

Root cause: N/A - this was a verification exercise, not a fault
investigation. Packet capture on the parent interface confirmed real
802.1Q VLAN ID 100 headers present on every relevant outbound frame.

Evidence:
Sub-interface created and confirmed:
$ sudo ip link add link enp1s0 name enp1s0.100 type vlan id 100
$ sudo ip link set enp1s0.100 up
$ ip -d link show enp1s0.100
  vlan protocol 802.1Q id 100 <REORDER_HDR> ...
$ sudo ip addr add 10.100.0.10/24 dev enp1s0.100

Capture on the PARENT interface (enp1s0), not the VLAN sub-interface -
capturing on the sub-interface would show traffic AFTER the kernel
already strips the tag, which would falsely look untagged even when
tagging works correctly:
$ sudo tcpdump -i enp1s0 -e -nn -vv 'vlan 100 or arp'
52:54:00:60:ac:85 > ff:ff:ff:ff:ff:ff, ethertype 802.1Q (0x8100),
  length 46: vlan 100, p 0, ethertype ARP (0x0806), ...
  Request who-has 10.100.0.1 tell 10.100.0.10
Confirms: ethertype 0x8100 and "vlan 100" present on every frame sent
through the sub-interface - real tagging, on the wire, not just
configuration intent.

Separate, unrelated observation (not a tagging issue):
$ ping -I enp1s0.100 -c 4 10.100.0.1
4 packets transmitted, 0 received, 100% packet loss
The ARP requests for 10.100.0.1 go out correctly tagged (visible in
the same capture) but receive no reply - there is no device on this
segment configured to answer for 10.100.0.1 in this lab environment.
This is a missing-peer condition, not a tagging defect.

What changed vs what stayed the same:
Changed: created enp1s0.100 VLAN sub-interface, assigned 10.100.0.10/24.
Stayed the same: parent interface enp1s0 config, routing, ARP state on
other interfaces.

Fix applied:
None required - tagging confirmed working correctly on first setup.

Automated or permanent version of the fix:
N/A. Operational takeaway: never trust ip link show / ip -d link show
alone to confirm tagging behavior - it only shows configuration, not
what's actually on the wire. Always verify with a capture on the
parent interface, since capturing on the VLAN sub-interface itself
would show traffic after the tag is already stripped.

Detection gap:
N/A - this was a deliberate verification exercise, not an incident
with a detection delay. The general lesson: config output confirming
intent is not the same as proof of wire behavior; always verify with
a capture at the correct point in the path.
