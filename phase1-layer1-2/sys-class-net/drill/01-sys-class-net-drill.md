TOPIC: /sys/class/net kernel interface statistics - static vs live fault
DATE STARTED: 2026-07-27
TARGET: answer all drills without checking reference

DRILL 1 - You need per-interface kernel receive/transmit statistics, more granular than ip -s link show. What's the path and first command?
YOUR ANSWER:
>
REFERENCE:
/sys/class/net/<if>/statistics/ - ls that path to see available counters (rx_errors, rx_dropped, rx_crc_errors, etc.)

DRILL 2 - rx_errors reads 0. Do you still need to check rx_over_errors, rx_crc_errors, rx_frame_errors, and rx_missed_errors individually?
YOUR ANSWER:
>
REFERENCE:
No - rx_errors is the parent/summary counter for that whole hardware/driver error category. Zero there rules out all of them in one check.

DRILL 3 - rx_dropped reads 43 (nonzero). Does this alone prove an active, ongoing packet-loss fault?
YOUR ANSWER:
>
REFERENCE:
No - kernel statistics are cumulative since interface init and never self-reset. A nonzero value could be entirely historical. Requires a controlled before/after test with real traffic to determine if it's still incrementing.

DRILL 4 - Design a controlled test to determine if rx_dropped is actively incrementing right now.
YOUR ANSWER:
>
REFERENCE:
cat the counter, generate real traffic (e.g. ping -c 20 <ip>), cat the counter again immediately after, compare. Equal values = no new drops during that traffic pattern.

DRILL 5 - A before/after ping test shows 0 new drops. Does this rule out ALL possible causes of the historical rx_dropped count?
YOUR ANSWER:
>
REFERENCE:
No - it only rules out drops caused by that specific traffic pattern (ICMP). A different traffic type (e.g. UDP flood, traffic hitting a firewall-scoped port) could still cause drops that ping never exercises.

DRILL 6 - You want to genuinely reproduce rx_dropped increments for testing, not just observe a static number. Why is a UDP flood (vs TCP) the right tool, and what iperf3 flags matter?
YOUR ANSWER:
>
REFERENCE:
UDP has no flow control/congestion backoff (unlike TCP), so it keeps sending even if the receiver can't keep up - genuinely stresses buffers. iperf3 -u (UDP) -b <rate> (target bitrate) -t <seconds> (duration) from the sender, with -s already running on the receiver.

DRILL 7 - After running a 10-second iperf3 UDP flood test, do you need to run a separate fix script to restore the interface to normal?
YOUR ANSWER:
>
REFERENCE:
No - the flood is time-bounded and self-resolving. No config or persistent state changes; the interface returns to normal traffic levels once iperf3 exits on its own.

SPEED ROUND - cover reference column, answer aloud:
List available kernel interface counters -> ls /sys/class/net/<if>/statistics/
Check hardware/driver error summary -> cat /sys/class/net/<if>/statistics/rx_errors
Check post-reception drop count -> cat /sys/class/net/<if>/statistics/rx_dropped
Generate controlled test traffic -> ping -c 20 <ip>
Start an iperf3 receiver -> iperf3 -s
Flood a receiver with high-bitrate UDP -> iperf3 -c <ip> -u -b 1G -t 10
Review firewall rule counters for context -> sudo nft -a list ruleset

WEAK SPOT LOG:
Date | What I got wrong | Fixed?
2026-07-27 | Ran commands from the wrong machine's repo clone without pulling first (repeat of earlier session's lesson) | Y
2026-07-27 | Initially unsure whether firewall drops would show in rx_dropped vs the firewall's own counters (different accounting layers) | Y
