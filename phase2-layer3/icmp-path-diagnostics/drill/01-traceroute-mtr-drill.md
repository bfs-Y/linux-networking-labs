TOPIC: traceroute and mtr - path diagnostics beyond ping
DATE STARTED: 2026-08-08
TARGET: answer all drills without checking reference

DRILL 1 - A colleague reports a destination "feels slow." Why isn't ping alone sufficient to diagnose this?
YOUR ANSWER:
>
REFERENCE:
ping only gives total round-trip time to the final destination - it can't show WHERE along the path any delay is occurring. traceroute/mtr show per-hop timing.

DRILL 2 - A traceroute shows "* * *" at hop 5, but hop 6 and the final destination respond successfully. Does this prove hop 5 is broken?
YOUR ANSWER:
>
REFERENCE:
No - hop 5 declined to reply to the probe specifically, but traffic clearly passed through it since later hops respond. A silent hop can still forward real traffic fine.

DRILL 3 - mtr shows 95% loss at one intermediate hop, but 0% loss at every hop after it, including the destination. Is this real packet loss at that hop?
YOUR ANSWER:
>
REFERENCE:
No - if that hop were genuinely dropping 95% of traffic, hops downstream could not show complete, clean delivery. This is that router deprioritizing reply-to-probe traffic, not real loss - confirm by pinging/mtr-ing that hop directly as its own target.

DRILL 4 - Write the mtr command for a 20-cycle, non-interactive report to 8.8.8.8.
YOUR ANSWER:
>
REFERENCE:
mtr -rc 20 8.8.8.8

DRILL 5 - A traceroute to a destination exhausts all 30 hops without ever reaching it, and the path repeatedly alternates between the same two addresses. What does this actually indicate, and how is it different from a normal "* * *" hop?
YOUR ANSWER:
>
REFERENCE:
A genuine routing loop - a real pathological failure, not a healthy silent hop. Unlike "* * *" (one hop declining to reply while forwarding fine), a loop never reaches the destination at all and shows a repeating pattern between the same addresses.

DRILL 6 - You want to simulate a router that appears silent to traceroute/mtr without breaking its ability to forward real traffic. What specific iptables rule achieves this?
YOUR ANSWER:
>
REFERENCE:
sudo iptables -I OUTPUT -p icmp --icmp-type time-exceeded -j DROP - blocks only the specific ICMP type traceroute/mtr rely on for hop replies, leaving real traffic forwarding untouched.

SPEED ROUND - cover reference column, answer aloud:
Run traceroute without reverse DNS lookups -> traceroute -n <target>
Run a 20-cycle mtr report -> mtr -rc 20 <target>
Block only ICMP time-exceeded replies -> sudo iptables -I OUTPUT -p icmp --icmp-type time-exceeded -j DROP
Remove that specific rule -> sudo iptables -D OUTPUT -p icmp --icmp-type time-exceeded -j DROP
Check which route the kernel will use for an address -> ip route get <ip>

WEAK SPOT LOG:
Date | What I got wrong | Fixed?
2026-08-08 | Initially unsure whether a high mtr loss% at one hop meant real packet loss without checking downstream hops first | Y
