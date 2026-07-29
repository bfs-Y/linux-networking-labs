TOPIC: Gratuitous ARP - mechanism, verification, and real limits
DATE STARTED: 2026-07-29
TARGET: answer all drills without checking reference

DRILL 1 - You need a peer's ARP cache to update immediately after a VIP moves to a new host, without waiting for natural cache expiry. What command, and what does the peer send back in response?
YOUR ANSWER:
>
REFERENCE:
sudo arping -U -I <if> -c 3 <ip> - sends an unsolicited announcement. Peers send 0 responses by design; this is a statement, not a query, so "Received 0 response(s)" is the correct expected result.

DRILL 2 - How do you prove a gratuitous ARP packet actually left the interface, and what does its packet signature look like compared to a normal ARP request?
YOUR ANSWER:
>
REFERENCE:
sudo tcpdump -i <if> -n arp - a gratuitous ARP shows the SAME IP in both "who-has" and "tell" fields (announcing your own address to yourself), unlike a normal request which asks about a different target.

DRILL 3 - A peer has NO existing ARP entry for a VIP. You send a gratuitous ARP. Does the peer create a new entry from it?
YOUR ANSWER:
>
REFERENCE:
Depends on net.ipv4.conf.<if>.arp_accept. With arp_accept=0 (common default), no - the peer only updates EXISTING entries, it won't create a new one from an announcement alone. The peer must resolve the address itself first (e.g. ping).

DRILL 4 - A peer has a PERMANENT ARP entry for the VIP (correct or wrong MAC). Does a gratuitous ARP update it?
YOUR ANSWER:
>
REFERENCE:
No - PERMANENT entries are immune to gratuitous ARP by design, same as they're immune to normal aging/reachability probing. Requires manual ip neigh del or avoiding PERMANENT entries on any IP that might migrate.

DRILL 5 - You run ip neigh replace <ip> lladdr <mac> dev <if> with no other flags, intending to create a normal test entry. What state does it actually land in, and why does that matter for a gratuitous ARP test?
YOUR ANSWER:
>
REFERENCE:
PERMANENT - ip neigh replace defaults to PERMANENT when no nud state is given. This silently defeats a gratuitous-ARP test unless you explicitly add "nud reachable" (or another non-permanent state).

DRILL 6 - A peer has a normal DYNAMIC entry with the WRONG MAC cached. You send a gratuitous ARP with the correct MAC. What state does the entry land in afterward, and why not REACHABLE?
YOUR ANSWER:
>
REFERENCE:
STALE - the MAC is corrected immediately, but gratuitous ARP involves no reply/round-trip confirmation, so the kernel can't yet confirm two-way reachability. It transitions to REACHABLE on the next real traffic exchange, same self-healing as any STALE entry.

DRILL 7 - You're designing failover automation that relies on gratuitous ARP to update every peer's cache. What real-world gap should you plan around, given what you now know?
YOUR ANSWER:
>
REFERENCE:
Some peers won't update at all - those with arp_accept=0 and no prior entry, or any peer with a PERMANENT static entry for the VIP. A periodic, independent reachability check is a more robust fallback than trusting gratuitous ARP unconditionally for every peer.

SPEED ROUND - cover reference column, answer aloud:
Send a gratuitous ARP announcement -> sudo arping -U -I <if> -c 3 <ip>
Capture ARP traffic to verify it went out -> sudo tcpdump -i <if> -n arp
Check whether a host accepts new entries from gratuitous ARP -> sysctl net.ipv4.conf.<if>.arp_accept
Create a normal (non-permanent) test entry -> sudo ip neigh replace <ip> lladdr <mac> nud reachable dev <if>
Force a real ARP resolution to create a baseline entry -> ping -c 2 <ip>
Check current entry state and MAC -> ip neigh show <ip>
Delete an entry manually (needed for PERMANENT entries) -> sudo ip neigh del <ip> dev <if>

WEAK SPOT LOG:
Date | What I got wrong | Fixed?
2026-07-29 | Assumed 0 responses from arping meant failure, not expected announce-mode behavior | Y
2026-07-29 | Ran arping from the wrong host (centos9 trying to announce ubuntulab's own IP) | Y
2026-07-29 | Didn't realize ip neigh replace defaults to PERMANENT without an explicit nud flag | Y
