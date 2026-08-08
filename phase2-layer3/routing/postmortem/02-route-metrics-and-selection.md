Date: 2026-08-07
Lab: Phase 2 (Layer 3) - Routing: metrics and route selection when multiple routes exist

Symptom (verbatim command and output):
On centos9 (CentOS Stream 9), wanted to verify what happens when two
routes exist to the same destination network (10.50.0.0/28) - does
the kernel pick randomly, use both, or is there a specific mechanism
deciding which one wins.

Root cause: N/A - verification exercise. Real, non-obvious finding:
two routes to the same destination with the SAME (or both default/
unspecified) metric are NOT kept as a genuine primary/backup pair -
the second one silently replaces the first. Only routes with
explicitly DIFFERENT metrics genuinely coexist.

Evidence:

Attempt 1 - same destination, no explicit metric on either route:
$ sudo ip route add 10.50.0.0/28 via 192.168.122.230 metric 0
  (original route via .226 had no metric specified either)
$ ip route show 10.50.0.0/28
  10.50.0.0/28 via 192.168.122.230 dev enp1s0
Only ONE route shown - the original via .226 was gone entirely,
confirmed absent from the full table (ip route show, no filter).
Adding a second route to an identical destination with an equal/
unspecified metric REPLACED the original rather than adding a backup.

Attempt 2 - same destination, explicit DIFFERENT metrics:
$ sudo ip route add 10.50.0.0/28 via 192.168.122.226 metric 100
$ sudo ip route add 10.50.0.0/28 via 192.168.122.230 metric 200
$ ip route show 10.50.0.0/28
  10.50.0.0/28 via 192.168.122.226 dev enp1s0 metric 100
  10.50.0.0/28 via 192.168.122.230 dev enp1s0 metric 200
BOTH routes genuinely coexist this time.

$ ip route get 10.50.0.1
  10.50.0.1 via 192.168.122.226 dev enp1s0 src 192.168.122.207
  uid 1000
Confirms: the LOWER metric (100) route is the one actually selected
for real traffic - lower metric = higher preference. The metric 200
route sits as a genuine, unused backup.

Side note: "uid 1000" in ip route get output is the user ID of the
process that triggered the lookup (confirmed via id -u matching) -
informational metadata, not a factor in route selection in this
simple setup.

What changed vs what stayed the same:
Changed: two temporary routes added and removed on centos9 during
testing, both cleaned up afterward, verified empty.
Stayed the same: ubuntulab's subnet config, the actual default route,
all other routing table entries.

Fix applied: N/A - verification, not an incident.

Automated or permanent version of the fix: N/A. Real operational
takeaway: to configure genuine primary/backup routing to the same
destination, you MUST specify explicit, distinct metrics on each
route. Relying on default/unspecified metrics for multiple routes to
the same destination risks silently losing one of them instead of
getting real redundancy.

Detection gap: N/A - deliberate, structured verification with a
prediction checked against real evidence at each step.
