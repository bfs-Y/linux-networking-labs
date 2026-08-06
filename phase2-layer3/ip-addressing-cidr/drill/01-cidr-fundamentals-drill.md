TOPIC: IP addressing and CIDR - subnet math, same/cross-subnet behavior, prefix mistakes
DATE STARTED: 2026-08-06
TARGET: answer all drills without checking reference

DRILL 1 - A /28 network has how many free bits for hosts, and how many total addresses does that give you?
YOUR ANSWER:
>
REFERENCE:
32 - 28 = 4 free bits. 4 free bits = 16 total addresses (each free bit doubles the count: 1=2, 2=4, 3=8, 4=16).

DRILL 2 - A /28 gives 16 total addresses. How many are actually usable by devices, and why?
YOUR ANSWER:
>
REFERENCE:
14 usable. The first address is always the network address (not assignable), the last is always the broadcast address (not assignable) - true for any subnet size, not just /28.

DRILL 3 - You assign 10.50.0.1/28 to an interface. What command shows you the automatically-created route, and what does "scope link" in its output mean?
YOUR ANSWER:
>
REFERENCE:
ip route show 10.50.0.0/28 - "scope link" means the kernel treats the whole block as directly reachable via this interface, no gateway needed.

DRILL 4 - You ping another address in your own /28 subnet, but nothing is actually there. What specific error appears, and why that message rather than a silent timeout?
YOUR ANSWER:
>
REFERENCE:
"Destination Host Unreachable" - the kernel tried to ARP-resolve the address (since it's directly reachable per the route), got no reply, and reports the failure immediately and explicitly.

DRILL 5 - You ping an address outside your subnet entirely (different /28 or /24). The ping just times out silently - no "unreachable" message. What's different about what's happening compared to DRILL 4?
YOUR ANSWER:
>
REFERENCE:
The kernel routed the packet via the default gateway (not ARP directly) since the address isn't in a directly-connected subnet. Silent loss means no reply ever came back along that routed path - a different failure layer than an ARP resolution failure.

DRILL 6 - An interface is accidentally assigned 10.50.0.1/24 instead of the intended 10.50.0.1/28. What's actually broken, even though the address itself looks correct?
YOUR ANSWER:
>
REFERENCE:
Subnet isolation - the wrong prefix makes the kernel treat a 256-address /24 range as directly reachable instead of the intended 16-address /28, silently defeating the whole purpose of carving out a small, isolated subnet.

DRILL 7 - Given a /24 split into consecutive /28 blocks (10.50.0.0/28, .16/28, .32/28...), what determines where each new block starts?
YOUR ANSWER:
>
REFERENCE:
Each block starts exactly 16 higher than the last, since each /28 is 16 addresses wide - blocks sit back-to-back with no gaps or overlaps.

SPEED ROUND - cover reference column, answer aloud:
Assign an address with a specific CIDR prefix -> sudo ip addr add <ip>/<prefix> dev <if>
Check the auto-created route for a subnet -> ip route show <network>/<prefix>
Check which route the kernel will actually use for an address -> ip route get <ip>
Calculate total addresses from free host bits -> 2^(free bits)
Calculate usable addresses from total -> total - 2 (network + broadcast)
Remove an address with a specific prefix -> sudo ip addr del <ip>/<prefix> dev <if>

WEAK SPOT LOG:
Date | What I got wrong | Fixed?
2026-08-06 | Initial CIDR math explanation didn't land - required full rebuild using plain analogies (apples doubling, streets/neighborhoods) before the concept stuck | Y
2026-08-06 | Guessed 8 doubled = 32 before correctly working through it as 8+8=16 | Y
2026-08-06 | Initially attributed "Destination Host Unreachable" to a firewall rule instead of recognizing the ARP-resolution-failure signature from earlier in the session | Y
