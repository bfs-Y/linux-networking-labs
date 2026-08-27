# Lab Notes: nsswitch.conf Resolution Order
Topic: NSS hosts database, files vs dns ordering

--- THE CORE MECHANISM ---
/etc/nsswitch.conf's hosts line lists lookup sources in order:
    hosts: files mdns4_minimal [NOTFOUND=return] dns
Each source is tried in sequence. Per man nsswitch.conf, without an
explicit [STATUS=ACTION] override, the DEFAULT actions are:
    success   -> return  (stop here, use this result)
    notfound  -> continue (try the next source)
    unavail   -> continue (try the next source)
    tryagain  -> continue (try the next source)
Only "success" stops the chain by default. Almost any failure mode
falls through to the next source automatically.

--- WHY REORDERING DOESN'T BREAK RESOLUTION ---
Putting dns before files does NOT break lookups of local names like
localhost or the machine's own hostname, because a DNS NXDOMAIN (or
timeout, or refusal) is a notfound/unavail/tryagain result - and all
three default to continue. Resolution still falls through to files
and succeeds. Confirmed live: hostname resolution worked identically
in both orders.

--- WHY REORDERING IS STILL A BAD IDEA ---
Even though it doesn't break correctness, it changes performance
characteristics. Every lookup that used to be a pure disk read now
potentially waits on a network round-trip first. The actual cost
depends entirely on how the DNS server responds to a miss:
  - Fast local resolver, quick negative response -> cost is negligible
    (confirmed this session: ~0.007-0.011s either order)
  - Slow, unreachable, or timing-out resolver -> cost could be seconds
    per lookup, on every name that used to be instant (not yet tested
    directly - see postmortem/03 open item)

--- MEASURING THIS CORRECTLY ---
A before/after timing test is only valid if both measurements start
from the same cache state. `resolvectl flush-caches` before EVERY
timed run is required - otherwise you're measuring cache temperature,
not resolution order. Learned the hard way: first attempt at this
lab compared a cold run to a warm run and got a backwards, misleading
result.

--- PRODUCTION RELEVANCE ---
This is exactly the kind of change that looks harmless in a quick
manual test (it still works!) and then causes real, hard-to-diagnose
latency in production once it depends on a resolver that isn't
always fast and always reachable. "Still resolves correctly" and
"resolves with acceptable performance" are two different claims -
verify both, not just the first.
