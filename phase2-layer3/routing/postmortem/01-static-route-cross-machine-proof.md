Date: 2026-08-06
Lab: Phase 2 (Layer 3) - Routing: static route needed for a subnet the gateway doesn't know

Symptom (verbatim command and output):
Set up 10.50.0.0/28 on ubuntulab (Ubuntu 24.04, enp7s0). A genuinely
separate machine, centos9 (CentOS Stream 9), needed to reach a device
inside that subnet (10.50.0.1). Wanted to prove, with real two-machine
evidence, whether the shared gateway (192.168.122.1) already knew how
to forward traffic there.

Root cause: The gateway/router only knows about networks it has been
explicitly told about (via static config or a routing protocol). It
never learns about a new subnet automatically just because a host on
its network assigned itself an address in that range - that knowledge
stays local to the host that created it, unless something explicitly
propagates it further.

Evidence:

Before any route was added:
$ sudo ip addr add 10.50.0.1/28 dev enp7s0   (on ubuntulab)
$ ping -c 2 10.50.0.1                          (from centos9)
  2 packets transmitted, 0 received, 100% packet loss (silent, no
  "unreachable" message)
$ ip route get 10.50.0.1                       (on centos9)
  10.50.0.1 via 192.168.122.1 dev enp1s0
Confirms: centos9 correctly determined 10.50.0.1 isn't on its own
directly-connected network and routed the attempt via its default
gateway (192.168.122.1) - the same gateway ubuntulab uses. That
gateway has no entry for 10.50.0.0/28, so the packet went nowhere -
silent loss, not an ARP-layer failure (different signature than
pinging an unused address within your own subnet).

Fix - added a static route on centos9 pointing directly at ubuntulab
(which DOES know its own /28, since it's directly attached):
$ sudo ip route add 10.50.0.0/28 via 192.168.122.226   (on centos9)
$ ip route show 10.50.0.0/28                            (on centos9)
  10.50.0.0/28 via 192.168.122.226 dev enp1s0
$ ping -c 2 10.50.0.1                                    (from centos9)
  2 packets transmitted, 2 received, 0% packet loss

Note on route syntax: the destination in a route is always written as
the NETWORK address (10.50.0.0, ending in .0) representing the whole
block, never a specific host address - the "via" target is the
specific device (192.168.122.226) that knows how to deliver traffic
once it arrives inside that network.

What changed vs what stayed the same:
Changed: 10.50.0.1/28 added to ubuntulab's enp7s0; a static route for
10.50.0.0/28 via 192.168.122.226 added on centos9.
Stayed the same: the actual libvirt/KVM gateway (192.168.122.1) was
never modified - the fix worked around it by routing directly to
ubuntulab instead, since ubuntulab itself can act as the delivery
point for its own subnet.

Fix applied: static route added on centos9, verified working with a
real ping test both before (failed) and after (succeeded).

Automated or permanent version of the fix: N/A for this lab - a real
production environment would either configure the actual router/
gateway with this route (so ALL hosts benefit, not just centos9), or
use a routing protocol to propagate it automatically. Adding a
per-host static route (as done here) only fixes reachability from
that one host - anyone else on the network would still fail the same
way until they also got the route, or the real gateway learned it.

Detection gap: N/A - this was a deliberate, structured verification
with a prediction checked against real evidence at each step (before/
after ping tests on a genuinely separate machine), not an incident
with a detection delay.
