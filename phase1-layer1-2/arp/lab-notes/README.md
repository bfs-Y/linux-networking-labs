# Lab Notes: ARP - Neighbor Table States and Diagnosis

## Objective
Understand ARP resolution, neighbor table states, and how to tell a
self-healing cache state (STALE) apart from a genuine, non-recovering
fault (PERMANENT with a wrong MAC).

## Baseline mechanism (see postmortem/README.md, 2026-07-10)
tcpdump capture showed strict ordering: ARP Request (broadcast) ->
ARP Reply (unicast) -> ICMP Echo. The kernel holds outbound IP
traffic until Layer 2 resolution completes. ARP Requests broadcast
because the sender doesn't know the target MAC yet; Replies are
unicast since the responder already learned the requester's MAC from
the Request frame itself.

## STALE state (not a fault)
    ip neigh show <ip>
STALE means "cached, but not recently confirmed" - not broken. The
kernel re-verifies automatically the moment real traffic is sent
(e.g. a ping), transitioning through reachability verification.
Check aging/probe evidence directly:
    ip -s -s neigh show <ip>
"used/confirmed/updated" timers past base_reachable_time explain a
STALE entry with no fault involved - normal garbage collection, not
an incident.

## PERMANENT state with a wrong MAC (real fault)
    ip neigh show <ip>
A PERMANENT entry never ages, never re-verifies - if the cached MAC
is wrong (e.g. a rebuilt VM, replaced NIC, or an injected fault),
traffic silently goes to a MAC nothing owns. This produces a SILENT
timeout (0% received, no message) - distinct from the fast, explicit
"Destination Host Unreachable" you get when there's no entry at all
and ARP resolution genuinely fails.

Reproduce (training/lab use):
    ./phase1-layer1-2/arp/break/01-stale-arp-entry.sh
    # injects a PERMANENT entry with a fake MAC for a target IP
Fix:
    sudo ip neigh del <ip> dev <if>
    ip neigh show <ip>   # confirm empty, kernel returns to on-demand ARP

## Lesson
"Cannot reach host" can come from very different ARP states that
look similar on the surface (both end in ping failure) but have
opposite fixes: STALE resolves itself, PERMANENT-with-wrong-MAC does
not and requires manual deletion. Always check ip neigh show before
assuming either.

## Process lessons from this session (non-ARP-specific but caught here)
- Verify which host you're actually on (hostname/prompt) before
  running any diagnostic command - repeated mistake this session.
- ip route get <ip> returning "local dev lo" means you queried an
  address that belongs to the querying host itself, not the target.
- A firewall ruleset's INPUT policy does not explain an outbound
  connectivity symptom - check direction before concluding relevance.
