Date: 2026-08-08
Lab: Phase 2 (Layer 3) - ICMP path diagnostics: traceroute/mtr verification, plus a real routing loop discovered

Symptom (verbatim command and output):
Case 1: a colleague reported reaching 8.8.8.8 "feels slow" - ping
alone gives total round-trip time but not where along the path any
delay occurs. Wanted to identify the actual location of any slowness.

Case 2 (self-directed follow-up): while verifying hop 5's apparent
95% loss in mtr wasn't real packet loss, tested traceroute against
10.50.0.1 (a private /28 this machine has no active route to, since
earlier routing-topic test routes had been cleaned up) and observed
a genuine, sustained routing loop.

Root cause:
Case 1: no fault. Path is healthy; the "slow" report was not
supported by measurement.
Case 2: real fault. With no local static route to 10.50.0.0/28 and
no legitimate upstream knowledge of that private range, the packet
is sent toward the real default gateway. Somewhere upstream
(172.20.152.2 / 172.20.152.3), routers alternate forwarding the
packet between each other repeatedly instead of returning a
"destination unreachable" - a genuine routing loop, not a healthy
"no route" rejection.

Evidence:

Case 1 - traceroute to 8.8.8.8:
$ traceroute 8.8.8.8
  13 hops, reaches dns.google (8.8.8.8) successfully. Hops 5, 11, 12
  show "* * *" - no reply, but NOT evidence of a break, since hop 13
  (the actual destination) responds successfully - traffic clearly
  passed through those silent hops.

$ mtr -rc 20 8.8.8.8
  All hops 0.0% loss except hop 5 (95.0% loss). Every hop AFTER hop 5
  shows 0.0% loss, including the final destination - if hop 5 were
  genuinely dropping 95% of traffic, downstream hops could not
  possibly show complete, clean delivery. Confirms: that router
  deprioritizes/rate-limits reply-to-probe traffic specifically,
  while forwarding real traffic normally.

Directly confirmed by isolating that one hop:
$ ping -c 20 10.206.179.195
  20 packets transmitted, 20 received, 0% packet loss
  (one outlier: 91.0ms on a single probe, otherwise 10-14ms range)
$ mtr -rc 20 10.206.179.195
  0.0% loss across all 20 cycles when queried directly
Confirms conclusively: the earlier 95% loss reading was an artifact
of how that hop responds to being an intermediate hop in a longer
trace, not evidence of real packet loss to or through it.

Final verdict for Case 1: dns.google (8.8.8.8) average round-trip
was 12.5ms (mtr) / 18.5ms (20-ping average, one outlier at 124ms
inflating the mean) - objectively fast. No evidence supports the
"slow" complaint.

Case 2 - real routing loop discovered:
$ ip route get 10.50.0.1
  10.50.0.1 via 192.168.122.1 dev enp1s0 src 192.168.122.226
  (routes via the real default gateway - no local knowledge of this
  private range in this context, since prior routing-topic test
  routes were already cleaned up)

$ traceroute -n 10.50.0.1
  All 30 hops exhausted, destination NEVER reached. From hop 5
  onward, the path alternates repeatedly between only two addresses:
  172.20.152.2 and 172.20.152.3, with escalating and highly variable
  timing (as high as 221ms on some probes) - the signature of a
  genuine routing loop, not a clean rejection.

What changed vs what stayed the same:
Nothing was changed - both cases were read-only diagnostic
investigations. The routing loop in Case 2 is a pre-existing
condition in the network path for this specific private-range
destination, discovered rather than caused.

Fix applied: N/A for Case 1 (nothing broken). N/A applied for Case 2
in this lab - the loop exists in infrastructure outside this host's
control (upstream of the real default gateway); the correct fix
would be adding an explicit route or blackhole for unroutable private
ranges, or fixing the upstream routers' handling of unknown
destinations - neither achievable from ubuntulab alone.

Automated or permanent version of the fix: N/A. Real operational
takeaway: traceroute/mtr's real value isn't just "is it slow" - it's
distinguishing a HEALTHY unresponsive hop (Case 1: silent but
forwarding fine) from a GENUINE pathological failure (Case 2: an
actual loop, confirmed by exhausting all 30 hops without reaching
the destination or getting a clean rejection).

Detection gap: Case 1's "* * *" hops and mtr's high-loss reading at
one hop could easily be misread as evidence of a real problem without
directly isolating and re-testing that specific hop - always confirm
by pinging/mtr-ing the suspicious hop directly, and by checking
whether hops AFTER it show clean delivery, before concluding it's
actually failing. Case 2 shows the opposite risk: assuming all
routing failures look the same (clean "unreachable" or silent
timeout) - a genuine loop produces neither, and only shows up as
"traceroute never terminates, hops repeat."
