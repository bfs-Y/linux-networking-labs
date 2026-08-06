Date: 2026-08-06
Lab: Phase 2 (Layer 3) - CIDR/subnet behavior verification (/28)

Symptom (verbatim command and output):
Wanted to verify, with real evidence rather than just calculation,
how a /28 subnet actually behaves on ubuntulab (Ubuntu 24.04) - same-
subnet reachability, cross-subnet routing, and the ARP-failure vs
routed-silent-loss distinction between them.

Root cause: N/A - this was a verification exercise, not a fault
investigation. All three tested behaviors matched expected mechanics
exactly.

Evidence:

Address assignment and automatic route creation:
$ sudo ip addr add 10.50.0.1/28 dev enp7s0
$ ip route show 10.50.0.0/28
  10.50.0.0/28 dev enp7s0 proto kernel scope link src 10.50.0.1
Confirms: assigning an address with a /28 prefix automatically creates
a "scope link" route - the kernel now treats the whole 16-address
block as directly reachable via this interface, no manual route
needed.

Case 1 - same-subnet address, nobody listening:
$ ping -c 2 10.50.0.5
  From 10.50.0.1 icmp_seq=1 Destination Host Unreachable (x2)
Confirms: same mechanism as an earlier ARP investigation this session
(centos9 powered off) - the kernel tried to ARP-resolve a directly-
routable address, got no reply, and reported failure immediately and
explicitly, rather than a silent timeout.

Case 2 - same-subnet address, real device present:
$ sudo ip addr add 10.50.0.5/28 dev enp1s0
$ ping -c 2 10.50.0.5
  2 packets transmitted, 2 received, 0% packet loss
Confirms: two addresses inside the same /28, on two different
interfaces, communicate directly - no gateway involved, matching the
"same neighborhood, walk over directly" model.

Case 3 - cross-subnet address (outside the /28 entirely):
$ ping -c 2 10.50.1.1
  2 packets transmitted, 0 received, 100% packet loss (silent, no
  "unreachable" message this time)
$ ip route get 10.50.1.1
  10.50.1.1 via 192.168.122.1 dev enp1s0 src 192.168.122.226
Confirms: a genuinely different failure signature from Case 1 - the
kernel correctly identified this address as NOT directly reachable,
routed the attempt via the default gateway instead of trying ARP
directly, and the silent loss reflects no reply ever coming back
along that path (since 10.50.1.1 doesn't exist anywhere real) -
not an ARP-layer failure like Case 1.

What changed vs what stayed the same:
Changed: temporarily added 10.50.0.1/28 to enp7s0 and 10.50.0.5/28
to enp1s0 for testing; both removed and verified clean afterward.
Stayed the same: enp1s0's real address (192.168.122.226/24), default
route, all other host config.

Fix applied: N/A - verification exercise, nothing was broken.

Automated or permanent version of the fix:
N/A. Real operational takeaway: "Destination Host Unreachable" vs
silent packet loss are DIFFERENT diagnostic signals - the former
means an ARP-layer failure on a directly-reachable address, the
latter means the packet was routed elsewhere (via a gateway) and
simply never got a reply. Don't treat all connectivity failures as
the same category of problem; the failure signature itself tells you
which layer to investigate first.

Detection gap: N/A - this was a deliberate, structured verification
with pre-formed predictions checked against real command output at
each step, not an incident with a detection delay.
