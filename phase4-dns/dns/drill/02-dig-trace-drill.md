TOPIC: dig +trace, recursive vs authoritative, delegation chain
DATE STARTED: 2026-08-28
TARGET: answer all drills without checking reference

DRILL 1 - What does dig +trace actually do, per its own documentation?
YOUR ANSWER:
>
REFERENCE:
Makes iterative queries following referrals from the root servers,
showing the answer from EACH server actually used to resolve the
lookup - not a guaranteed fixed number of hops.

DRILL 2 - A dig response has the aa flag set, and the answer came from
127.0.0.53 (your local stub resolver). Does aa prove the answer is
correct for the real, public internet domain?
YOUR ANSWER:
>
REFERENCE:
No - aa means "authoritative for whatever source this server is
answering from" (which could be a locally synthesized /etc/hosts
entry), not "verified correct for the real internet zone."

DRILL 3 - dig +trace example.com shows only 2 hops (root list, then a
final answer) instead of the textbook root->TLD->authoritative 3 hops.
Is this necessarily a broken trace?
YOUR ANSWER:
>
REFERENCE:
Not necessarily - root servers can hold enough delegation/glue info to
resolve some queries in fewer visible hops. Delegation depth is real
but variable, not a fixed 3-step guarantee.

DRILL 4 - How do you check a domain's real, authoritative nameservers
directly, separate from an A record lookup?
YOUR ANSWER:
>
REFERENCE:
dig <domain> NS - returns the delegated nameserver records directly.

DRILL 5 - You run the same dig query twice, several minutes apart, and
want to know if the second answer is a stale cached result or a fresh
fetch. What do you check, and what pattern would indicate "cached"?
YOUR ANSWER:
>
REFERENCE:
Compare the TTL values. If the second TTL is roughly the first TTL
minus the elapsed seconds, that's a decaying cache. If it's similar to
or higher than the original (inconsistent with simple decay), it's
more likely a fresh fetch.

DRILL 6 - dig +trace against a host with broken/absent routable IPv6
shows repeated "network unreachable" messages mixed into otherwise
normal output. Why does this happen with +trace specifically, when a
plain (non-traced) dig query doesn't show this?
YOUR ANSWER:
>
REFERENCE:
+trace makes YOU contact each server directly, including IPv6-only-
addressed root servers - failures are visible. A plain query lets your
configured resolver handle retries/fallback internally, hiding the
same underlying IPv6 unreachability from you.

SPEED ROUND - cover reference column, answer aloud:
Check a domain's real nameservers -> dig <domain> NS
aa flag means -> authoritative FOR THIS SOURCE, not verified-correct
+trace hop count is -> variable, not fixed at 3
Verify cached vs fresh -> compare TTL decay against elapsed time
IPv6 issues show up in -> +trace specifically, hidden in plain queries

WEAK SPOT LOG:
Date | What I got wrong | Fixed?
2026-08-28 | Assumed dig +trace showing 2 hops instead of 3 meant something was broken - it was correct behavior per documented delegation/glue behavior, confirmed via man dig | Y
2026-08-28 | Initially suspected a fake/spoofed root server response before verifying the IP (192.58.128.30) against an independent source - turned out to be a genuine root server | Y
