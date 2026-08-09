# Lab Notes: traceroute and mtr - Path Diagnostics Beyond ping

## Why ping isn't enough
ping gives total round-trip time only - it can't show WHERE along a
path any delay is happening. traceroute and mtr show each hop
individually.

## traceroute - one snapshot, per-hop timing
    traceroute <target>
    traceroute -n <target>   # -n skips reverse DNS, faster/cleaner output

Each numbered line is one router (hop) along the path, with 3 timing
probes per hop.

"* * *" at a hop does NOT necessarily mean a break. It means that
specific hop declined to reply to the probe - it can still be
forwarding real traffic perfectly fine. Proof: if a LATER hop (closer
to the destination) responds successfully, traffic clearly passed
through the silent one.

## mtr - continuous, statistical view over time
    mtr -rc 20 <target>
-r = report mode (prints once, non-interactive). -c 20 = 20 cycles.

Shows Loss%, and Last/Avg/Best/Wrst/StDev timing per hop, across
multiple cycles - catches intermittent issues a single traceroute
snapshot could miss.

CRITICAL gotcha: a high Loss% at ONE hop does not mean real packet
loss, if every hop AFTER it shows 0% loss (including the final
destination). A router genuinely dropping most traffic could not
possibly let everything downstream arrive cleanly. High loss at one
hop, healthy loss everywhere after = that router deprioritizes reply-
to-probe traffic specifically, not a real network problem.

Confirmed directly this session: hop showing 95% loss in mtr (as an
intermediate hop) showed 0% loss and normal timing when pinged/mtr'd
DIRECTLY as the actual target instead of as a pass-through hop.

## Distinguishing a healthy silent hop from a genuine failure
Healthy: traceroute/mtr shows gaps or high loss at intermediate hops,
but the FINAL destination is reached successfully with reasonable
timing.

Genuine failure (a real routing loop, confirmed this session against
a private-range destination with no valid route): traceroute exhausts
ALL hops (e.g. all 30) without ever reaching the destination, and the
path repeatedly alternates between the same 1-2 addresses - not a
clean "unreachable" rejection, an actual loop.

## Simulating a "silent hop" safely for testing
    sudo iptables -I OUTPUT -p icmp --icmp-type time-exceeded -j DROP
Blocks only the specific ICMP type traceroute/mtr rely on for hop
replies - the host still forwards real traffic normally, same
behavior as a real router that just doesn't reply to probes.
Fix: remove the rule (iptables -D ... same rule).

## Lesson
Don't conclude a path is broken from a single hop's non-response or
high loss reading. Always check what happens at hops AFTER the
suspicious one, and directly re-test the suspicious hop as its own
target before drawing conclusions. The real failure signature to
watch for is exhausting all hops with no destination reached and a
repeating pattern between the same few addresses - that's a genuine
loop, not a silent-but-healthy router.
