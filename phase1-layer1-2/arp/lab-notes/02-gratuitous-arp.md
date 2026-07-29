# Lab Notes: Gratuitous ARP - Announcing an IP Change Without Waiting

## Objective
Understand gratuitous ARP as an unsolicited announcement mechanism, and
confirm its real behavior/limits (as opposed to assuming it "just works"
against any peer state).

## The mechanism
A gratuitous ARP is an ARP packet a host sends unprompted - "this IP is
now at MY MAC," broadcast to the whole segment, with no prior query from
anyone. This is how failover tooling (VRRP, keepalived) makes a VIP move
between hosts take effect immediately instead of waiting for every
peer's ARP cache to expire naturally.

    sudo arping -U -I <if> -c 3 <ip>
-U = unsolicited/announce mode. Sends 0 responses back by design - this
is a statement, not a question, so "Received 0 response(s)" is the
CORRECT, expected result, not a failure.

## Verifying it actually went out
    sudo tcpdump -i <if> -n arp
Real gratuitous ARP packets appear as:
    ARP, Request who-has <ip> tell <ip>
Same IP in both "who-has" and "tell" fields is the signature of a
self-announcement, distinguishing it from a normal ARP request.

## What actually happens on the receiving peer - three cases

### Case 1: peer has no prior entry for this IP
Result: NOTHING HAPPENS. The entry stays empty.
Reason: net.ipv4.conf.<if>.arp_accept controls this. With arp_accept=0
(a common default), a host only updates EXISTING entries from a
gratuitous ARP - it will not create a brand new one from an
announcement alone. The peer must resolve the address itself first
(e.g. ping) before gratuitous ARP has anything to act on.
    sysctl net.ipv4.conf.<if>.arp_accept

### Case 2: peer has a PERMANENT entry (right or wrong)
Result: NOTHING HAPPENS. Gratuitous ARP does not touch it.
Reason: PERMANENT means the kernel will never age it, never re-verify
it, and - confirmed by direct test - never update it from an incoming
gratuitous ARP either. This is a real production risk: a peer with a
manually-pinned static ARP entry for a VIP will silently NOT follow a
failover, no matter how many gratuitous ARPs are sent. Requires manual
intervention (ip neigh del) or avoiding PERMANENT entries for any IP
that might migrate.
Note: ip neigh replace defaults to PERMANENT when no nud state is
given explicitly - a subtle trap if you intend to create a normal,
mutable entry for testing.

### Case 3: peer has a normal DYNAMIC/mutable entry (wrong or stale)
Result: CORRECTLY UPDATED. This is the case gratuitous ARP is designed
for and actually works as expected.
The entry lands in STALE state after the update, not REACHABLE -
because the announcement involves no reply/round-trip confirmation.
It self-heals to REACHABLE the next time real traffic flows to it and
gets a response, same aging behavior as any other STALE entry.

## Lesson
Gratuitous ARP is not a universal fix-all for cache staleness during
failover. Its real-world reliability depends on every peer's specific
ARP configuration (arp_accept) and entry state (PERMANENT vs DYNAMIC).
Production failover automation relying on gratuitous ARP alone should
account for peers that won't update from it - a periodic independent
reachability check is a more robust fallback than trusting the
announcement mechanism unconditionally.
