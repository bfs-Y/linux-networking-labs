TOPIC: nsswitch.conf resolution order, defaults, and measurement pitfalls
DATE STARTED: 2026-08-27
TARGET: answer all drills without checking reference

DRILL 1 - /etc/nsswitch.conf's hosts line lists "files" before "dns"
with no explicit [STATUS=ACTION] overrides on dns. If a DNS lookup
returns NXDOMAIN, does resolution stop there, or continue?
YOUR ANSWER:
>
REFERENCE:
Continue - notfound's default action is "continue" per man
nsswitch.conf, unless an explicit override changes it.

DRILL 2 - Name the three NSS status codes whose default action is
"continue" rather than "return".
YOUR ANSWER:
>
REFERENCE:
notfound, unavail, tryagain. Only "success" defaults to "return".

DRILL 3 - Reordering nsswitch.conf to put dns before files for the
hosts database - does this break resolution of localhost? Why or why not?
YOUR ANSWER:
>
REFERENCE:
No - DNS returning NXDOMAIN for localhost is a notfound result, which
defaults to continue, so resolution falls through to files and still
succeeds. Confirmed live in this lab.

DRILL 4 - If reordering doesn't break resolution, what's the actual
risk of putting dns before files?
YOUR ANSWER:
>
REFERENCE:
Performance, not correctness - every lookup that used to be a free
disk read now potentially waits on a network round-trip first. The
cost depends on how fast the DNS server responds to a miss (fast
local resolver = negligible cost; slow/unreachable resolver = real,
possibly multi-second cost per lookup).

DRILL 5 - You time a lookup before and after a config change, and the
"after" result is faster. Before concluding the change improved
performance, what should you check first?
YOUR ANSWER:
>
REFERENCE:
Whether the two measurements started from the same cache state. A
warm cache from the first run can make the second run look faster
regardless of the actual variable being tested - flush caches before
each timed measurement to get a valid comparison.

DRILL 6 - What command flushes systemd-resolved's local DNS cache?
YOUR ANSWER:
>
REFERENCE:
sudo resolvectl flush-caches

SPEED ROUND - cover reference column, answer aloud:
Default action for notfound -> continue
Default action for success -> return
Flush systemd-resolved cache -> sudo resolvectl flush-caches
Does dns-first break localhost -> no, falls through to files
Real risk of dns-first -> latency, not correctness

WEAK SPOT LOG:
Date | What I got wrong | Fixed?
2026-08-26 | First timing test confounded cache state with resolution order - drew a backwards conclusion from an invalid comparison | Y
