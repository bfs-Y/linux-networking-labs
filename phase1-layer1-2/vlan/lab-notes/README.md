# Lab Notes: 802.1Q VLAN Tagging - Creation and Verification

## Objective
Create a VLAN sub-interface and prove, from real wire evidence rather
than trusting config output, that 802.1Q tagging is genuinely present.

## Create a VLAN sub-interface
    sudo ip link add link enp1s0 name enp1s0.100 type vlan id 100
    sudo ip link set enp1s0.100 up
    sudo ip addr add 10.100.0.10/24 dev enp1s0.100

## Verify configuration (config-level, not proof of wire behavior)
    ip -d link show enp1s0.100
Shows "vlan protocol 802.1Q id 100" - this confirms INTENT/CONFIG only,
same trust level as ethtool's config output earlier in this session.
Does not prove tagging is actually happening on real frames.

## Verify tagging is genuinely on the wire (authoritative proof)
    sudo tcpdump -i enp1s0 -e -nn -vv 'vlan 100 or arp'
CRITICAL: capture on the PARENT interface (enp1s0), never the VLAN
sub-interface (enp1s0.100). The kernel strips the 802.1Q tag before
handing a frame to the sub-interface - capturing there would show
untagged traffic even when tagging is working correctly, producing a
false negative.

Real tagged frame looks like:
    ethertype 802.1Q (0x8100), length 46: vlan 100, p 0, ethertype ARP...
"ethertype 802.1Q (0x8100)" and "vlan <id>" are the actual tag markers
present in the frame - this is the only reliable confirmation.

## Lesson
Never trust ip link show / ip -d link show alone to confirm tagging
behavior - it only shows configuration, not what's actually on the
wire. Always verify with a capture on the PARENT interface. If a
downstream report of untagged frames doesn't match what your own
capture shows, the fault likely lives further down the path (an
access-mode switch port, a non-VLAN-aware device) - not on this host,
and cannot be confirmed or ruled out without a capture taken closer to
the reported problem point.
