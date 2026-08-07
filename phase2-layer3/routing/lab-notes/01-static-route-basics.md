# Lab Notes: Static Routing - Why a Gateway Doesn't Automatically Know

## Core concept
A router/gateway only knows about networks it's been explicitly told
about - either through manual (static) configuration, or a routing
protocol exchanging that information automatically. Creating a new
subnet on one host does NOT automatically teach the gateway (or any
other machine) about it - that knowledge stays local until something
propagates it.

Analogy: a gateway is a gate with someone standing there holding a
map. They only know the streets written on that map. If a new street
gets built and nobody tells them, the map is out of date - they can't
send anyone there.

## Proving it, two machines, real evidence
Host A (ubuntulab) creates a subnet:
    sudo ip addr add 10.50.0.1/28 dev enp7s0

Host B (centos9), a genuinely separate machine, tries to reach it:
    ping -c 2 10.50.0.1
    -> 100% loss, SILENT (no "Destination Host Unreachable")

Check what actually happened:
    ip route get 10.50.0.1
    -> routed via the default gateway, since Host B has no more
       specific route - the gateway doesn't know this subnet either,
       so the packet goes nowhere. Silent loss = routed-but-no-reply,
       different signature than an ARP-layer failure (which is
       immediate and explicit).

## The fix: add a static route
    sudo ip route add <destination-network> via <next-hop>

Two different addresses in that command, doing different jobs:
- destination network (e.g. 10.50.0.0/28) - always written using the
  NETWORK address (ending in .0), representing the whole block, not
  one device.
- next-hop / "via" address (e.g. 192.168.122.226) - a SPECIFIC device
  that knows how to deliver traffic once it reaches that network.

Real example: ubuntulab is directly attached to 10.50.0.0/28, so it
already knows that subnet. Pointing centos9's route "via" ubuntulab's
real address lets ubuntulab act as the delivery point, even though
it's not the actual libvirt/KVM gateway.

## Verify
    ip route show <network>       # confirm the route exists
    ping -c 2 <address-inside-it> # confirm real connectivity, 0% loss

## Real limitation of this fix
A static route added on ONE host (centos9) only fixes reachability
from that host. Every other machine on the network would still fail
the same way until they also get the route, or the actual gateway
learns it (via config or a routing protocol). This is a workaround
for a single host, not a network-wide fix.

## Lesson
"It should just work" assumptions about routing are usually wrong -
a subnet existing is not the same as a subnet being reachable from
everywhere. Always verify with ip route get on the machine that's
failing, not just on the machine that owns the subnet.
