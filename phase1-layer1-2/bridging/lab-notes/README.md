# Lab Notes -- Linux Bridge + veth + Network Namespace

Date: 2026-07-20

## Objective
Build a Linux bridge from scratch, attach a veth pair correctly (one end
on the bridge, the other end in an isolated network namespace), and prove
traffic actually crosses the bridge with real evidence -- not just
`ip link` output.

## What Was Built
1. `br0` -- created, brought up, assigned 10.10.10.1/24
2. `veth-host` / `veth-ns` -- veth pair created
3. `veth-host` attached to `br0` as a bridge member, brought up
4. `lab1` -- network namespace created (simulates an isolated host)
5. `veth-ns` moved into `lab1`, renamed to `eth0`
6. Inside `lab1`: `lo` and `eth0` brought up, `eth0` assigned 10.10.10.2/24

## Evidence
- `ping 10.10.10.2` from the host (outside the namespace) to the namespace:
  0% packet loss, real RTTs (~0.09-0.24ms)
- `ping 10.10.10.1` from inside `lab1` back to the host bridge IP:
  0% packet loss, real RTTs (~0.10-0.16ms)
- `bridge fdb show` confirmed the bridge's forwarding database correctly
  learned veth-host's MAC address behind that port
- `bridge link` showed `state forwarding` on veth-host once attached and up
- `ip netns exec lab1 ip neigh` confirmed the namespace correctly resolved
  and cached the bridge's MAC via ARP

## Correct Architecture (and why the first attempt was wrong)
Initial attempt plugged BOTH ends of the same veth pair into the same
bridge (`veth-a` and `veth-b` both `master br0`). This is a Layer 2 loop
-- functionally identical to plugging both ends of one Ethernet cable
into the same unmanaged switch. A veth pair is a virtual cable meant to
connect two DIFFERENT network contexts (e.g. a bridge to a namespace or
container), not to loop back into the same one.

Correct pattern: one veth end joins the bridge; the other end is moved
into a separate namespace (or container) entirely. This mirrors exactly
how Docker (`docker0` + `vethXXXX` + container's `eth0`) and Kubernetes
CNI plugins work under the hood -- same primitives, no magic.

## System Instability (separate issue)
Multiple system hangs occurred during this session, requiring several
reboots. Diagnosed with free/uptime/top: not caused by memory or disk
pressure (both healthy throughout). One hang correlated with a runaway
Firefox renderer process at 100% CPU (confirmed via ps). Root cause of
all hangs not fully confirmed; noted as a separate operational issue, not
a networking lab fault.

## Not Yet Covered
802.1Q VLAN tagging -- creating a VLAN sub-interface and confirming the
tag is actually present in a packet capture (not just `bridge vlan show`
output). Deferred to a future session.
