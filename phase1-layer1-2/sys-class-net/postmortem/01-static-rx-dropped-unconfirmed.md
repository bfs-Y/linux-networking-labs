Date: 2026-07-27
Lab: Phase 1 (Layer 1/2) - /sys/class/net, reported intermittent packet loss investigation

Symptom (verbatim command and output):
Reported: intermittent packet loss on ubuntulab (Ubuntu 24.04), enp1s0,
path to centos9 (192.168.122.207). Not total failure, sporadic drops
during traffic.

$ cat /sys/class/net/enp1s0/statistics/rx_dropped
43

Root cause: No live fault demonstrated - rx_dropped held static at 43
across a controlled 20-packet test window, meaning the counter reflects
historical or otherwise-unattributed drops, not an active, ongoing
packet-loss condition.

Evidence:
- rx_errors = 0, tx_errors = 0, tx_dropped = 0 - ruled out hardware/
  driver-level fault categories entirely.
- rx_dropped = 43, confirmed nonzero and real (not a phantom count).
- Controlled before/after test:
    Before: rx_dropped = 43
    ping -c 20 192.168.122.207 -> 20 transmitted, 20 received, 0% loss
    After:  rx_dropped = 43
    Delta: 0 new drops during the test window.
- Repeated independently a second time with the same result (43 -> 43).
- Path also confirmed healthy via prior investigations this session:
  MTU (DF-bit ping at 1472 bytes, 0% loss), throughput (700MB scp,
  completed clean), gateway reachability (0% loss).
- nft -a list ruleset reviewed: INPUT chain policy is drop; only a
  narrow allowlist (tcp/80, tcp+udp/22 and tcp/5201 scoped to
  192.168.122.0/24) is explicitly accepted, everything else falls
  through to the default drop with no logging unless rate-limited.
  This is a PLAUSIBLE explanation for unattributed historical drops
  but was NOT confirmed against the specific 43 - no capture or
  counter correlation was performed at the time those drops occurred.

What changed vs what stayed the same:
Nothing was changed. No config touched on either host. This was a
read-only investigation.

Fix applied:
None - no active fault was demonstrated to fix. Changing firewall
rules or any other config based on an unconfirmed, non-incrementing
counter would not be evidence-based and risks fixing a problem that
may not exist while breaking something that does work correctly.

Automated or permanent version of the fix:
N/A - no fault confirmed. If this symptom is reported again, the
correct action is real-time correlation: watch rx_dropped continuously
while the reported loss is actually occurring, with a simultaneous
tcpdump capture, so any future drop can be tied to a specific packet,
time, and (if applicable) a specific firewall rule counter - rather
than inspecting a static counter after the fact with no timing
context.

Detection gap:
A static kernel counter with no timestamp or correlated capture
cannot, by itself, establish an active fault - same detection gap as
three earlier incidents this session (phantom gateway fault, phantom
throughput fault, unreproduced MTU "hang"). The recurring lesson:
always test whether a reported symptom is currently reproducible
before investigating root cause, and never conclude causation from
a single static number without a controlled before/after comparison.
