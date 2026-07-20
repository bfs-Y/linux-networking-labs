# Postmortem

Date: 2026-07-20

Lab: Phase 1 -- Bridging: veth pair attached to both ends of the same bridge

## Symptom (verbatim command and output)

Command:
sudo ip link set veth-a master br0
sudo ip link set veth-b master br0
sudo ip link set veth-a up
sudo ip link set veth-b up
ip link show veth-a
ip link show veth-b

Output:
15: veth-a@veth-b: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue
    master br0 state UP mode DEFAULT group default qlen 1000
    link/ether 1a:0a:54:9c:89:6a brd ff:ff:ff:ff:ff:ff
14: veth-b@veth-a: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue
    master br0 state UP mode DEFAULT group default qlen 1000
    link/ether 8a:42:31:24:10:bb brd ff:ff:ff:ff:ff:ff

Both ends of the same veth pair show `master br0` simultaneously.

## Root Cause

A veth pair is a single virtual cable with two ends. Attaching both ends
to the same bridge as separate ports creates a Layer 2 loop: a frame
entering one end exits the other, re-enters the bridge, and the cycle
repeats indefinitely. This is the software equivalent of plugging both
ends of one Ethernet cable into the same unmanaged switch.

## Evidence

- `ip link show` output above confirms both `veth-a` and `veth-b` carried
  `master br0` at the same time -- the misconfiguration itself is directly
  confirmed by this output, independent of any other system behavior.
- No packet-counter evidence (`ip -s link show br0`) was captured before
  the bridge was removed, so an active broadcast storm was never directly
  measured -- the loop's existence is confirmed by topology (both ends on
  one bridge), not by observed traffic volume.

## What Changed vs What Stayed the Same

Changed:
- Bridge topology: went from a single veth end attached to br0 (correct)
  to both ends attached to br0 (incorrect loop) during experimentation,
  then corrected back to the proper namespace-based architecture.

Stayed the same:
- The host's other network interfaces and existing libvirt bridges
  (virbr0, virbr1, virbr2) were unaffected throughout.

## Fix Applied

Removed the looped veth pair and rebuilt using the correct architecture:
one veth end attached to the bridge, the other end moved into an isolated
network namespace (`ip netns add`, `ip link set <if> netns <namespace>`).
Verified with bidirectional ping (0% packet loss both directions) after
rebuilding correctly. Full corrected sequence documented in
`phase1-layer1-2/bridging/lab-notes/README.md`.

## Automated or Permanent Version of the Fix

`phase1-layer1-2/bridging/fix/01-rebuild-lab-topology.sh` -- a reusable
script that tears down any leftover bridge/veth/namespace state and
rebuilds the correct topology from scratch, so this exact mistake (both
veth ends on one bridge) is never manually re-typed.

## Detection Gap

No causal link was established between this networking misconfiguration
and the system slowdowns observed during the same session -- those
slowdowns were separately investigated and at least partly attributed to
an unrelated runaway Firefox renderer process (confirmed via `ps`/`top`
showing 100% CPU usage), not to this bridge loop. Packet-counter evidence
(`ip -s link show br0`) should be captured immediately when a loop is
suspected, before any teardown, to confirm or rule out active storm
traffic rather than relying on topology alone.

## Note: VLAN Tagging Not Yet Covered

This bridging topic (lab-notes, drill, break, fix, postmortem) covers
bridge creation, veth pairs, and namespace isolation only. 802.1Q VLAN
tagging -- creating a VLAN sub-interface and confirming the tag appears
in an actual packet capture -- has not been covered and remains open on
the Phase 1 backlog.
