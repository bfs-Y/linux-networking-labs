Date: 2026-08-26 to 2026-08-27
Lab: Phase 4 (DNS) - nsswitch.conf reorder, latency cost investigation

Hypothesis:
Reordering /etc/nsswitch.conf's hosts line from "files ... dns" to
"dns files" would measurably slow down lookups that should resolve
locally (e.g. the machine's own hostname), because a real network
query would be attempted before falling through to /etc/hosts.

Reasoning basis (confirmed via man nsswitch.conf before testing):
notfound, unavail, and tryagain all default to action "continue" - so
reordering does NOT break resolution outright (fallthrough to files
still happens), but was expected to add a real time cost per lookup.

First attempt (2026-08-26) - FLAWED, retracted:
Ran break/02-nsswitch-reorder.sh v1. Timed one lookup before reorder,
one lookup after. Result: BEFORE was slower (0.051s) than AFTER
(0.005s) - the opposite of the hypothesis.

Root cause of the flawed result: the test was confounded. BEFORE was
a genuinely cold lookup (first of the session). AFTER reused a warm
resolver cache from the BEFORE run - so the comparison measured
"cold vs warm cache," not "files-first vs dns-first." Caught by
running three additional lookups (still dns-first, then restored to
files-first, then repeated) - all landed in the same fast ~0.005-
0.011s range regardless of order, proving order wasn't the variable
that mattered in the first test.

Second attempt (2026-08-27) - corrected:
Rewrote break/02-nsswitch-reorder.sh v2 to call
`sudo resolvectl flush-caches` before EVERY timed measurement, so both
conditions start from the same cold state.

Evidence (both cold):
  BASELINE (files-first, flushed): real 0m0.011s
  AFTER (dns-first, flushed):      real 0m0.007s
  REPEAT (dns-first, warm cache):  real 0m0.006s

Result: no meaningful difference between cold files-first and cold
dns-first in this environment. The hypothesis's mechanism is real
(NSS would attempt dns first), but the measured cost in THIS lab
setup is negligible.

Why the magnitude is small here (reasoned, not yet independently
verified against a slow/unreachable resolver):
The configured DNS server (192.168.122.1, a local libvirt gateway) is
on-subnet, low-latency, and likely returns NXDOMAIN or refuses a bare
unqualified hostname ("ubuntulab", no domain suffix) almost instantly
rather than incurring a real internet round-trip or a timeout. The
notfound/continue fallthrough to files therefore costs almost nothing
measurable in this specific setup.

Conclusion:
Reordering nsswitch.conf to dns-first does not break local resolution
(confirmed via documented NSS defaults) and its latency cost is
real in principle but environment-dependent in practice - a fast,
reachable resolver returning a quick negative response costs little;
a slow, unreachable, or timing-out resolver would cost much more
(seconds, not milliseconds). This lab's local libvirt DNS server is
the former case, not the latter.

What changed vs what stayed the same:
Changed: nsswitch.conf hosts line order (during test only, restored
after). Test script rewritten to flush cache before each measurement.
Stayed the same: resolution correctness - localhost/hostname lookups
worked in both orders, confirming the documented NSS fallthrough
behavior held true in practice, not just on paper.

Automated or permanent version: fix/02-nsswitch-restore.sh restores
from backup and flushes the cache, confirmed working.

Detection gap / lesson generalized:
A before/after timing comparison is only valid if both measurements
start from the same "temperature" (cache state, warm-up state, etc.).
Comparing a cold run to a warm run measures the cache, not the
variable actually being tested - same class of mistake as trusting a
verification command without confirming what state it's actually
reading (getent hosts vs ahosts, DNS postmortem 02).

Open item:
Magnitude claim ("slow resolver = real cost") is reasoned, not tested.
A genuine test would require pointing resolution at a deliberately
slow or unreachable DNS server and re-measuring - not yet attempted.
