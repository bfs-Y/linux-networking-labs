TOPIC: 802.1Q VLAN tagging - creation, verification, and misconfiguration
DATE STARTED: 2026-07-30
TARGET: answer all drills without checking reference

DRILL 1 - You need to create a VLAN sub-interface for VLAN ID 100 on enp1s0. What's the command sequence?
YOUR ANSWER:
>
REFERENCE:
sudo ip link add link enp1s0 name enp1s0.100 type vlan id 100
sudo ip link set enp1s0.100 up
sudo ip addr add <ip>/<prefix> dev enp1s0.100

DRILL 2 - ip -d link show enp1s0.100 shows "vlan protocol 802.1Q id 100." Does this prove tagging is actually happening on the wire?
YOUR ANSWER:
>
REFERENCE:
No - this only confirms configuration/intent. It does not prove real frames carry the tag. Requires a packet capture to confirm actual wire behavior.

DRILL 3 - You want to verify 802.1Q tagging is genuinely present in outbound frames. Which interface do you capture on - the VLAN sub-interface or the parent - and why does it matter?
YOUR ANSWER:
>
REFERENCE:
The PARENT interface (e.g. enp1s0, not enp1s0.100). The kernel strips the 802.1Q tag before handing frames to the sub-interface - capturing there produces a false negative (looks untagged even when tagging works correctly).

DRILL 4 - What does a genuinely tagged frame look like in tcpdump -e output, specifically?
YOUR ANSWER:
>
REFERENCE:
"ethertype 802.1Q (0x8100)" followed by "vlan <id>" in the frame header - these are the actual tag markers; their absence means the frame is genuinely untagged.

DRILL 5 - A colleague assigns an IP address directly to the parent interface, believing this configures VLAN 100. What's actually wrong with this, and what would a capture show?
YOUR ANSWER:
>
REFERENCE:
No VLAN sub-interface was ever created, so no 802.1Q tag is ever added - traffic sent this way is genuinely untagged. A capture would show plain ethertype (e.g. ARP 0x0806 or IPv4 0x0800) with no 802.1Q layer at all.

DRILL 6 - A downstream team reports seeing untagged frames from a host you're responsible for, but your own capture on that host's parent interface shows correct 802.1Q tags on every frame. What can and can't you conclude?
YOUR ANSWER:
>
REFERENCE:
You can conclude tagging is correct AT THIS HOST. You cannot rule out a fault further downstream (e.g. a switch port in access mode instead of trunk, stripping the tag) - that requires a separate capture taken at or near the downstream point; a single-host capture only proves what that host itself sends.

SPEED ROUND - cover reference column, answer aloud:
Create a VLAN sub-interface -> sudo ip link add link <parent-if> name <if>.<vlanid> type vlan id <vlanid>
Bring a VLAN sub-interface up -> sudo ip link set <if>.<vlanid> up
Assign an address to a VLAN sub-interface -> sudo ip addr add <ip>/<prefix> dev <if>.<vlanid>
View VLAN config detail on an interface -> ip -d link show <if>.<vlanid>
Verify tagging is on the wire (correct interface) -> sudo tcpdump -i <parent-if> -e -nn -vv 'vlan <id>'
Delete a VLAN sub-interface -> sudo ip link del <if>.<vlanid>

WEAK SPOT LOG:
Date | What I got wrong | Fixed?
2026-07-30 | Nearly proposed testing wrong VLAN ID or wrong IP as the "untagged" fault, not realizing neither produces genuinely untagged frames | Y
2026-07-30 | Ran fix script against an interface that already existed from earlier testing, without cleaning up state first | Y
2026-07-30 | HTTPS git push failed with password auth - required generating a Personal Access Token for this machine | Y
