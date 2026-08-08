# Lab Notes: Route Metrics and Selection

## Core concept
A metric is a number attached to a route saying how preferred it is.
Lower number = higher preference. Same idea as choosing between two
roads to the same destination - the "better" road (lower metric) gets
picked first.

## The real trap: same/default metrics don't create redundancy
Adding a second route to a destination that ALREADY has a route,
without specifying a distinct metric, does NOT create a backup route.
Proven directly: it silently REPLACED the original route instead -
confirmed missing from the full routing table afterward.

    sudo ip route add <network> via <next-hop-A>          # no metric
    sudo ip route add <network> via <next-hop-B> metric 0  # also no
                                                             # real distinction
    ip route show <network>
    -> only ONE route shown - the first one is gone

## The fix: explicit, distinct metrics
    sudo ip route add <network> via <next-hop-A> metric 100
    sudo ip route add <network> via <next-hop-B> metric 200
    ip route show <network>
    -> BOTH routes shown this time - genuine coexistence

Confirm which one actually gets used for real traffic:
    ip route get <address-inside-network>
    -> selects the LOWER metric route (100, not 200)

## Real-world DHCP example
A DHCP-assigned default route commonly gets an explicit metric (e.g.
metric 100) set automatically by the client/NetworkManager - not left
as a silent default. Confirmed directly via:
    ip route show
    -> default via <gateway> ... metric 100

## The uid field in ip route get output
    10.50.0.1 via 192.168.122.226 dev enp1s0 src 192.168.122.207
    uid 1000
"uid 1000" is the user ID of the process that triggered the lookup
(confirmed matches id -u) - informational only in a simple setup, not
a routing decision factor unless policy-based routing is configured.

## Lesson
Don't assume adding a second route automatically gives you a working
backup path - it might silently overwrite the first one instead.
Always explicitly set distinct metrics when the intent is genuine
primary/backup routing, and verify with ip route show (not just "the
command didn't error") that both routes actually still exist.
