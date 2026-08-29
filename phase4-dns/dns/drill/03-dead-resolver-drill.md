TOPIC: Dead resolver latency, temporary DNS overrides, revert reliability
DATE STARTED: 2026-08-28
TARGET: answer all drills without checking reference

DRILL 1 - Roughly how much time does a single DNS lookup cost against
a genuinely unreachable resolver, compared to a working one?
YOUR ANSWER:
>
REFERENCE:
~30 seconds (client-side resolver timeout) vs well under 1 second for
a working resolver - confirmed live: 0.382s vs 31.548s.

DRILL 2 - What command temporarily redirects a single interface's DNS
server without editing /etc/resolv.conf or nsswitch.conf directly?
YOUR ANSWER:
>
REFERENCE:
sudo resolvectl dns <interface> <server-ip>

DRILL 3 - You point DNS at an unreachable IP for testing, then run
`sudo resolvectl revert <interface>` expecting the original DNS
server to come back. What actually happened when this was tested live?
YOUR ANSWER:
>
REFERENCE:
It did NOT restore the original config - it left the interface with
"Current Scopes: none" and no DNS server at all, a different broken
state. The proven fix was cycling the NetworkManager connection
(nmcli connection down/up) to force a fresh DHCP re-fetch.

DRILL 4 - A dead-resolver timing test against "example.com" showed
suspiciously fast results even with DNS pointed at an unreachable
server. What was the actual cause, and what command exposed it?
YOUR ANSWER:
>
REFERENCE:
A stale poisoned /etc/hosts entry for example.com from an earlier lab
was never cleaned up - files is checked before dns, so the lookup
never reached the dead resolver at all. Exposed via `grep example.com
/etc/hosts`.

DRILL 5 - When picking a target IP to simulate an "unreachable"
resolver for testing, why choose a genuinely unused IP on the local
subnet rather than a real server that just refuses connections?
YOUR ANSWER:
>
REFERENCE:
Timeout (no response at all) and refused (an active rejection) are
different failure modes with very different costs - an unused IP
produces a true timeout, which is the specific, more expensive
scenario being tested here.

DRILL 6 - What's the general lesson about trusting a command named
"revert" or "restore"?
YOUR ANSWER:
>
REFERENCE:
A command's name is not a guarantee of its actual effect - verify the
resulting state directly (e.g. resolvectl status showing a real DNS
server) rather than trusting the command's exit code or what its name
implies it should do.

SPEED ROUND - cover reference column, answer aloud:
Cost of unreachable resolver -> ~30 seconds per lookup
Temporary per-interface DNS override -> resolvectl dns <iface> <ip>
resolvectl revert reliable on this system -> No - use nmcli connection down/up
Verify a test domain has no local override -> grep <domain> /etc/hosts
Timeout vs refused -> no response at all vs active rejection

WEAK SPOT LOG:
Date | What I got wrong | Fixed?
2026-08-28 | First dead-resolver test used a domain (example.com) with a stale /etc/hosts poison entry from an earlier lab, invalidating the result - caught via direct grep before drawing conclusions | Y
2026-08-28 | Assumed resolvectl revert would restore original DNS state - it left the interface with no DNS config at all, had to find the real recovery method (nmcli cycling) | Y
