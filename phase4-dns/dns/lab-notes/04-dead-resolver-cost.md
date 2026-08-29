# Lab Notes: Dead Resolver - Real Cost, Real Recovery
Topic: DNS resolution timeout behavior, tool "revert" reliability

--- THE CORE FINDING ---
An unreachable DNS server costs approximately 30 seconds per lookup
(client-side resolver timeout), versus well under half a second for
a working resolver. Confirmed live: 0.382s (working, 192.168.122.1)
vs 31.548s (unreachable, 192.168.122.250). This is the real-world
magnitude behind the abstract risk flagged in the nsswitch-reorder
lab (postmortem/03) - reordering nsswitch.conf doesn't break
resolution outright, but if the DNS source it now checks first is
ever unreachable, the cost isn't negligible, it's a near-total hang
from a user's perspective.

--- FIRST TEST ATTEMPT WAS INVALID - CAUGHT BEFORE CONCLUDING ---
Initial run used "example.com" as the test domain and got fast
results even against a confirmed-unreachable resolver. Root cause:
/etc/hosts still had a stale poisoned entry for example.com from the
earlier hosts-override topic, never cleaned up between labs. Since
files is checked before dns, the lookup never reached the dead
resolver at all - same recurring stale-artifact pattern as
postmortem/01. Lesson: verify the actual resolution PATH taken
(grep /etc/hosts) before trusting a timing result, especially when
testing a domain used in an earlier, unrelated lab.

--- resolvectl revert IS NOT A RELIABLE UNDO ---
After the dead-resolver test, `sudo resolvectl revert enp1s0` was
expected to restore the original DNS config. It did not - it left
the interface with "Current Scopes: none" and no DNS server listed
at all, a different broken state, not the original working one.
The proven recovery was cycling the NetworkManager connection
(`nmcli connection down/up netplan-enp1s0`), which forces a fresh
DHCP re-fetch and correctly restores the real DNS server.
Generalized lesson: a tool's own "revert"/"undo" command name is not
a guarantee of what it actually does - verify the resulting state
directly (resolvectl status showing a real DNS server) rather than
trusting the revert command's exit code or its name's implication.

--- SAFE WAY TO TEST AGAINST A DEAD RESOLVER ---
Used `resolvectl dns <iface> <dead-ip>` - a temporary, per-interface
override, reversible in principle (though see above re: revert's
unreliability) - rather than editing /etc/resolv.conf or
nsswitch.conf directly. Picked a genuinely unused IP on the local
subnet (confirmed via `ip neigh show` + a failed ping) rather than a
real-but-refusing server, to get a true timeout rather than a fast
rejection - those are different failure modes with different costs.

--- PRODUCTION RELEVANCE ---
A resolver that's merely SLOW or fully unreachable (not just
returning a fast negative answer) can turn what looks like a minor
config choice (resolution order, or resolver selection) into a
near-total service hang, multiplied across every DNS lookup an
application makes. Health-check and failover logic for DNS resolvers
matters for exactly this reason - a single slow/dead resolver in a
chain can be far more damaging than one that's simply wrong.
