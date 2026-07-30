Date: 2026-07-30
Lab: Phase 1 - 802.1Q VLAN tagging verification

Symptom (verbatim command and output):
Training scenario (not a real reported incident): a VLAN sub-interface (enp1s0.100) was configured on
ubuntulab (Ubuntu 24.04), with a hypothetical premise that a
downstream switch/monitoring team reported seeing UNTAGGED frames
arriving on that segment, breaking VLAN isolation - used as the basis for a hands-on verification exercise.

Root cause: No tagging fault found on ubuntulab. Packet capture on the
parent interface (enp1s0) directly confirmed real 802.1Q VLAN ID 100
headers present on every relevant outbound frame. The downstream
"untagged frames" report is not supported by evidence from this host.

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

Separate, unrelated observation (not a tagging fault):
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
None required on ubuntulab - no fault found here. If the downstream
report is accurate, the fault must live between this host and the
downstream observation point (e.g. a switch port configured for access
mode instead of trunk, stripping the tag; or an intermediate device
that isn't VLAN-aware). A single-host capture cannot prove or disprove
a fault at that point - would require a capture taken AT or NEAR the
downstream location itself.

Automated or permanent version of the fix:
N/A - no fault found on this host to automate a fix for. Operational
takeaway: when a tagging complaint spans multiple hops, verify each
hop independently with its own capture rather than trusting one
endpoint's clean result to vindicate or condemn the whole path.

Detection gap:
The original report ("untagged frames downstream") could not be
confirmed or denied by testing only the originating host. Capturing
on the wrong interface (the VLAN sub-interface instead of the parent)
would have produced a MISLEADING false-negative - traffic already
untagged by the time it reached that virtual interface, even with
correct tagging happening beneath it. Always capture on the parent
interface when verifying 802.1Q tagging is genuinely present on the
wire.
