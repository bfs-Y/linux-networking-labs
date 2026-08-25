Date: 2026-08-25
Lab: Phase 1 (Layer 1/2) - bridge + veth + network namespace, systematic
teardown sequence (break/01-veth-namespace-teardown-sequence.sh)

Symptom / Purpose:
Not a real incident - a designed fault-injection sequence. The break
script builds a working bridge/veth/namespace topology (br0, veth-host
<-> veth-ns/eth0 in netns lab1, 10.10.10.1/10.10.10.2), confirms it works
(0% packet loss), then hands off four manual break scenarios meant to be
run and predicted one at a time:
  BREAK 1: bring down host-side veth end (veth-host down)
  BREAK 2: bring down namespace-side veth end (eth0 down inside lab1)
  BREAK 3: delete the namespace entirely
  BREAK 4: delete the now-empty bridge

Evidence (BREAK 3 only - re-verified live this session):
Ran fix/01-rebuild-lab-topology.sh first to confirm a real, working
topology existed (0% packet loss confirmed via ping before testing).

Before:
$ sudo ip link show veth-host
9: veth-host@if8: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue
master br0 state UP mode DEFAULT group default qlen 1000
    link/ether 7e:1a:c7:de:3f:45 brd ff:ff:ff:ff:ff:ff link-netns lab1

$ sudo ip netns del lab1

After:
$ sudo ip link show veth-host
Device "veth-host" does not exist.

Confirmed: deleting the namespace destroyed the host-side veth end too,
with no separate delete command run against veth-host. This matches the
break script's own stated expectation ("same kernel object, both ends of
a veth pair are removed together") - but this session is the first time
that expectation was actually verified against live evidence rather than
just trusted from the script's comment.

Root cause / mechanism:
A veth pair is a single kernel object with two visible interface ends.
Deleting either end (directly, or indirectly by deleting the namespace
that contains one end) destroys both ends simultaneously - they are not
two independent interfaces linked by configuration, they're one object.

What changed vs what stayed the same:
Changed: nothing in the scripts. This session only re-ran the existing
break/fix scripts and observed real output for BREAK 3, which had
previously been assumed/undocumented rather than confirmed.
Stayed the same: the underlying kernel veth-pair behavior - it worked
as designed, this session just replaced assumption with evidence.

What I missed (process note, not a script defect):
An initial verification attempt was run against an already-torn-down
topology (no lab1 namespace existed, so deleting it and checking
veth-host proved nothing - veth-host was already absent going in).
Caught before drawing a false conclusion from it: re-ran fix/ to rebuild
a real topology first, then repeated the before/after check properly.
Lesson: a before/after test is only valid if "before" is confirmed to be
in the expected starting state - checking that a command's output
changed means nothing if the starting state was already wrong.

BREAK 1, 2, and 4: NOT re-verified this session. No confirmed evidence
exists in this repo's history for what actually happened when veth-host
was brought down, when eth0 (namespace side) was brought down, or when
the empty bridge was deleted. The script's inline comments state expected
outcomes for these (e.g. BREAK 4: "clean removal, no dependent objects
remain") but per this session's own evidence standard, an expected
outcome in a comment is not the same as an observed result. These remain
open - documented here as a known gap, not filled in with assumption.

Fix applied: N/A - this is a designed teardown lab, not an incident.
fix/01-rebuild-lab-topology.sh correctly and idempotently rebuilds the
full topology from any torn-down state (uses `|| true` on cleanup
commands so it doesn't fail if something's already absent) - confirmed
working live this session.

Detection gap / lesson generalized:
Trusting a script's own comment as if it were observed evidence is the
same failure mode already documented in DNS postmortem 02 (getent hosts
vs ahosts) and the loadbalancer postmortems this phase - a claim of
success or a predicted behavior is not evidence until it's been checked
against real command output, every time, no exceptions for comments
that "sound right."

Open item:
Re-run BREAK 1, 2, and 4 with the same before/after evidence discipline
used for BREAK 3 above, and update this postmortem with confirmed
results rather than leaving them as documented gaps.
