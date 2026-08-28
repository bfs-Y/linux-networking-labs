# Lab Notes: dig +trace, Recursive vs Authoritative
Topic: DNS delegation chain, root/TLD/authoritative servers

--- THE CORE MECHANISM ---
Per `man dig`: "+trace ... dig makes iterative queries to resolve the
name being looked up. It follows referrals from the root servers,
showing the answer from each server that was used to resolve the
lookup." It shows every server ACTUALLY consulted - not a fixed,
guaranteed number of hops.

--- WHAT "AUTHORITATIVE" ACTUALLY MEANS ---
The aa flag in a dig response means "this server is answering from
its own authoritative zone data for this record" - not "this answer
is definitely correct." A local stub resolver (127.0.0.53) can set aa
when synthesizing an answer from /etc/hosts, because from ITS
perspective, /etc/hosts is its authoritative local source - even
though it has zero relationship to the real internet zone for that
domain. Confirmed live earlier this phase (hosts-override topic):
poisoned /etc/hosts entries produced aa-set responses from the stub.

--- THE "3-HOP" ASSUMPTION IS WRONG ---
Textbook DNS teaching often implies: root -> TLD -> authoritative,
always 3 hops. Real testing (dig +trace wikipedia.org) showed only
2 visible hops before a final answer - root server list, then a
single root server's response containing the resolved A record
directly, with no separately-visible ".org TLD server" line. This is
NOT a bug or a broken trace. Root servers can hold enough delegation/
glue information to resolve some queries in fewer visible hops than
the idealized model. Delegation depth is real but variable, not fixed.

--- SEPARATING NS RECORDS FROM A RECORDS ---
`dig wikipedia.org` (A record) and `dig wikipedia.org NS` (nameserver
record) are different queries with different answers. The NS query
directly confirmed wikipedia.org's REAL authoritative nameservers
(ns0/ns1/ns2.wikimedia.org) - useful for verifying delegation exists
and is queryable independently of how many hops a trace happens to show.

--- IPv6 CAN SILENTLY DEGRADE A TRACE ---
Live evidence: dig +trace repeatedly failed against IPv6-addressed
root servers ("network unreachable") because this host has no working
routable IPv6, only link-local. dig retried multiple root servers
before landing on one reachable over IPv4. This is invisible in a
plain (non-traced) query since the resolver handles retries
internally - +trace exposes it because YOU are making each hop
directly. A host with broken/absent IPv6 will show intermittent,
seemingly random extra delay or failed-attempt noise in +trace output
that has nothing to do with the domain being queried.

--- VERIFYING A RESULT ISN'T STALE/CACHED ---
Method used this session: run the identical query twice, a known
number of seconds apart, and check whether the TTL value decreased by
roughly that many seconds (cached, counting down) or came back at a
similar/different fresh value (freshly re-fetched). Confirmed live:
TTL went 23 -> 95 across ~8 minutes - inconsistent with a decaying
cache, consistent with fresh re-fetches of a genuinely short-TTL
record (common for CDN-backed services like Wikipedia).

--- PRODUCTION RELEVANCE ---
Don't assume a "weird-looking" dig +trace output means something is
broken - verify against documented behavior (man dig) and separate,
targeted queries (NS-only, repeated timing) before concluding a tool
or a network path is faulty. The mental model of "always 3 clean
hops" is a simplification; real DNS infrastructure resolves in a
variable number of hops depending on what the root/TLD servers
already know.
