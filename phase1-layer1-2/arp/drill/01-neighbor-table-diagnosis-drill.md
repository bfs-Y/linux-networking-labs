TOPIC: ARP - Neighbor Table Diagnosis (STALE vs PERMANENT, host verification)
DATE STARTED: 2026-07-21
TARGET: answer all drills without checking reference

DRILL 1 - You're told to diagnose "VM can't reach the gateway." Before running any diagnostic command, what's the first thing you verify, and why?
YOUR ANSWER:
>
REFERENCE:
Check the shell prompt/hostname - confirm you're on the actual target host, not your laptop or another box. Wrong-host diagnosis burns your fastest window with zero real evidence.

DRILL 2 - ip neigh show <ip> returns a STALE entry for a host you can otherwise ping successfully. Is this the fault?
YOUR ANSWER:
>
REFERENCE:
No - STALE means unconfirmed-but-cached, not broken. It self-heals the moment real traffic (e.g. ping) triggers reachability verification.

DRILL 3 - ip neigh show <ip> returns a PERMANENT entry with a MAC address. Ping to that IP times out with zero output - no "unreachable" message. What does PERMANENT tell you the kernel is doing, and why is this failure silent?
YOUR ANSWER:
>
REFERENCE:
Kernel believes it already has a valid MAC and skips ARP entirely - sends frames straight to that MAC. If no device owns it, frames vanish with no error generated back to you. PERMANENT never ages or re-verifies.

DRILL 4 - Ping to a target returns "Destination Host Unreachable" from your own IP. What does that message tell you about the ARP layer, versus a silent 100% loss timeout with no such message?
YOUR ANSWER:
>
REFERENCE:
"Unreachable" = kernel tried ARP resolution and got no reply - fast, informative failure, no entry exists. Silent timeout = kernel already has a (possibly wrong) MAC cached and sent frames with no reply - check ip neigh show immediately, don't trust ping's silence.

DRILL 5 - You need to remove a bad PERMANENT ARP entry for 192.168.122.207 on interface enp1s0. What's the exact command, and what do you run immediately after to confirm it worked?
YOUR ANSWER:
>
REFERENCE:
sudo ip neigh del 192.168.122.207 dev enp1s0, then ip neigh show 192.168.122.207 - empty output confirms removal. No error is not confirmation by itself.

DRILL 6 - nft list ruleset shows OUTPUT policy accept and INPUT policy drop. A user reports "my VM can't reach anything on the bridge." Does this ruleset explain that symptom? What's your next move if it doesn't?
YOUR ANSWER:
>
REFERENCE:
No - OUTPUT accept means this host's outbound traffic isn't restricted here. INPUT drop restricts what reaches this host, wrong direction for an outbound symptom. Check the far-end host's firewall instead.

DRILL 7 - You're handed an interface name in a ticket (e.g. ens3). Before running any command against it, what do you check first?
YOUR ANSWER:
>
REFERENCE:
ip link show with no arguments - confirm the name actually exists on this host. Never trust a name handed to you by a ticket, teammate, or scenario description.

SPEED ROUND - cover reference column, answer aloud:
Confirm interface has real carrier, not just admin UP -> ip link show <if> (check LOWER_UP flag)
List all interfaces by real kernel name -> ip link show
Show IP addresses per interface -> ip addr show
Show kernel routing decision for a destination -> ip route get <ip>
Show ARP/neighbor table -> ip neigh show
Show neighbor entry with timing/probe stats -> ip -s -s neigh show <ip>
Delete a specific bad ARP entry -> ip neigh del <ip> dev <if>
Show active nftables rules being enforced -> nft list ruleset

WEAK SPOT LOG:
Date | What I got wrong | Fixed?
2026-07-21 | Jumped to ARP before confirming Layer 1 | Y
2026-07-21 | Ran commands on wrong host (laptop, not lab VM) | Y
2026-07-21 | Queried own IP's route (local dev lo) instead of gateway | Y
2026-07-21 | Assumed STALE = fault without checking probe/timing evidence | Y
2026-07-21 | Confused gateway IP (.1) with actual break-script target (.207) | Y
2026-07-21 | Read firewall INPUT rules as explaining an outbound symptom | Y
2026-07-21 | Ctrl+C instead of Ctrl+D when saving heredoc - lost content | Y
