TOPIC: Nmap inventory scanning, exposure validation vs firewall config
DATE STARTED: 2026-09-05
TARGET: answer all drills without checking reference

DRILL 1 - What Nmap flag performs host discovery only, with no port
scanning, useful for a fast subnet-wide inventory?
YOUR ANSWER:
>
REFERENCE:
-sn

DRILL 2 - What flag scans ALL 65535 ports instead of the default
~1000 most common ports?
YOUR ANSWER:
>
REFERENCE:
-p-

DRILL 3 - A firewall's config explicitly allows traffic to port 5201
(e.g. for iperf3). A full port scan shows 5201 as CLOSED, not open.
Does this mean the firewall rule is broken or misconfigured?
YOUR ANSWER:
>
REFERENCE:
No - it means nothing is currently listening on that port. A firewall
rule describes what COULD become reachable if a service starts
listening; it doesn't mean something is listening right now. This is
expected for a service like iperf3 that only listens when manually
started.

DRILL 4 - What's the actual definition of "exposure validation" as a
distinct discipline from just reading a firewall config?
YOUR ANSWER:
>
REFERENCE:
Actively confirming what's genuinely reachable right now via a live
scan or direct check, rather than trusting what a config says SHOULD
be reachable - the two can and do differ (allowed-but-dormant vs
actually-listening).

DRILL 5 - A scan labels a port with a default service name (e.g.
"zeus-admin" for 9090). Should this be trusted as a verified
identification of what's running there?
YOUR ANSWER:
>
REFERENCE:
No - it's a static port-number database guess. Verify with -sV
(actual service probing) or direct host knowledge/checks
(systemctl status, firewall-cmd) before trusting it.

DRILL 6 - You scan a host and see "Not shown: 65375 filtered
(no-response), 157 filtered (admin-prohibited)." What does this tell
you about the firewall's behavior across those ports?
YOUR ANSWER:
>
REFERENCE:
Most of those ports (65375) are silently dropped with no reply at
all; a smaller subset (157) get an active, explicit rejection message
instead - two different firewall behaviors applied to different port
ranges/rules, not a single uniform block.

SPEED ROUND - cover reference column, answer aloud:
Fast subnet host discovery -> nmap -sn <subnet>
Scan all 65535 ports -> nmap -p- <target>
Firewall allows a port but scan shows closed -> nothing currently listening, not a misconfiguration
Verify a scanner's service guess -> -sV or direct host check
Real current attack surface -> what's actually open/listening right now, not what's merely permitted

WEAK SPOT LOG:
Date | What I got wrong | Fixed?
