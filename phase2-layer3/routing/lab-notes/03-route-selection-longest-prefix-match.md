# Lab Notes -- Route Selection: Longest Prefix Match

Date: 2026-08-20

## Objective
Prove that when multiple routes match the same destination, the kernel
selects the MOST SPECIFIC route (longest prefix / smallest range), not
the broadest or oldest one -- even when a shorter-prefix route still
technically matches too.

## Concept
A /32 route (one exact address, "the apartment") is more specific than
a /24 route (256 addresses, "the street"), which is more specific than
a default route, 0.0.0.0/0 (every address, "the whole city"). All three
can match the same destination simultaneously; the kernel always prefers
the longest matching prefix.

## What Was Done
1. Baseline: `ip route get 192.168.122.207` -- resolved via the existing
   connected /24 route (`dev enp1s0`, no gateway hop).
2. Added a deliberately more-specific /32 route for that same address,
   pointing through the gateway instead:
   `sudo ip route add 192.168.122.207/32 via 192.168.122.1`
3. Re-checked `ip route get 192.168.122.207` -- now resolved via the
   gateway (`via 192.168.122.1 dev enp1s0`), even though the /24 route
   was still present in the table and still technically matched.
4. Removed the /32 route; re-verified behavior reverted to the original
   direct /24 path.

## Evidence
Before:  192.168.122.207 dev enp1s0 src 192.168.122.226
After:   192.168.122.207 via 192.168.122.1 dev enp1s0 src 192.168.122.226
Reverted: 192.168.122.207 dev enp1s0 src 192.168.122.226 (matches "Before")

The only variable changed was the presence of the /32 route -- confirms
the kernel's selection is driven purely by prefix specificity, not route
order, age, or any other factor.

## Real-World Relevance
This exact mechanism underlies VPN split-tunneling and policy routing:
forcing one specific host or subnet through a different path without
touching the broad default route.
