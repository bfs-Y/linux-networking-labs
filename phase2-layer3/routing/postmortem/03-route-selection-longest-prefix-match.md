# Postmortem

Date: 2026-08-20

Lab: Phase 2 -- Route Selection: Longest Prefix Match

## Symptom (verbatim command and output)

Command: ip route get 192.168.122.207
Before: 192.168.122.207 dev enp1s0 src 192.168.122.226 uid 1001

Command: sudo ip route add 192.168.122.207/32 via 192.168.122.1
Command: ip route get 192.168.122.207
After: 192.168.122.207 via 192.168.122.1 dev enp1s0 src 192.168.122.226 uid 1001

## Root Cause

Two routes matched the same destination address simultaneously: the
existing /24 connected route (192.168.122.0/24, direct via enp1s0) and a
deliberately injected /32 host route (192.168.122.207/32, via the
gateway). The kernel selected the /32 route because it is the longest
matching prefix -- more specific than the /24 -- regardless of the fact
that the /24 route was already present and otherwise valid.

## Evidence

Before/after ip route get output shows the ONLY variable changed was the
presence of the /32 route. Route order, route age, and metric were not
factors -- confirmed by removing the /32 route afterward and observing
the routing decision revert exactly to its original state.

## What Changed vs What Stayed the Same

Changed: kernel's selected route for 192.168.122.207, from direct
(dev enp1s0) to via-gateway (via 192.168.122.1).

Stayed the same: the /24 connected route itself was never modified or
removed -- it remained present and valid throughout, simply outranked
by the more specific /32 route.

## Fix Applied

sudo ip route del 192.168.122.207/32 via 192.168.122.1

Verified with ip route get 192.168.122.207 -- reverted to direct
delivery via the connected /24 route, matching the original baseline.

## Automated or Permanent Version of the Fix

phase2-layer3/routing/fix/03-remove-more-specific-route.sh -- removes
the injected /32 route and re-verifies the result automatically.

## Detection Gap

A host routing through an unexpected gateway, while its subnet's
connected route looks completely normal, is easy to misdiagnose as a
gateway or DHCP problem. The actual cause -- an extra, more-specific
route sitting elsewhere in the table -- is only visible by reading the
FULL routing table (`ip route`), not just the subnet's own connected
route entry. `ip route get <destination>` is the fastest way to confirm
which route is actually in effect before assuming any other layer is at
fault.
