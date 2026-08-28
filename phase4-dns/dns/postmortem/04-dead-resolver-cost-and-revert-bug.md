Date: 2026-08-28
Lab: Phase 4 (DNS) - dead resolver latency, closing the open item from
postmortem/03 (nsswitch-reorder-latency.md)

Purpose:
postmortem/03 found that reordering nsswitch.conf to dns-first cost
almost nothing against a fast, reachable local resolver (~0.007-
0.011s), and left as an open item: what does it cost against a slow
or unreachable resolver instead? This lab answers that directly.

First attempt - invalid, caught before drawing conclusions:
Initial run of break/03-dead-resolver.sh used "example.com" as the
test target and got fast results (~0.03s) even after pointing DNS at
a confirmed-unreachable IP (192.168.122.250, verified via ping: 100%
loss, not in `ip neigh show`). Root cause: /etc/hosts still had a
stale poisoned entry for example.com from an earlier DNS lab
(hosts-override topic) that was never cleaned up - same recurring
class of mistake as postmortem/01 (stale manual poison contaminating
later tests). /etc/hosts is checked before dns per nsswitch.conf, so
the lookup never reached the (dead) resolver at all in either run.
Fixed: removed the stale example.com entries from /etc/hosts, switched
the test target to wikipedia.org (a real domain with no local
override), re-ran.

Real result (corrected):
  BASELINE (real resolver, 192.168.122.1):     real 0m0.382s
  TEST (unreachable resolver, 192.168.122.250): real 0m31.548s

Conclusion: CONFIRMED. An unreachable DNS server costs approximately
30 seconds per lookup (waiting for the client-side resolver timeout),
versus well under half a second for a working resolver. This closes
the open item from postmortem/03: the magnitude of the reordering
risk is entirely dependent on resolver health - negligible against a
fast/reachable server, catastrophic (30+ seconds, effectively a hang
from a user's perspective) against an unreachable one.

Second real finding - resolvectl revert bug on this system:
After the dead-resolver test, ran `sudo resolvectl revert enp1s0`
expecting it to restore the original DNS config. Instead:
$ resolvectl status enp1s0
  Current Scopes: none
  (no DNS Servers line at all)
revert cleared the override but did not restore the DHCP-provided
config - left the interface in a different broken state (no DNS at
all) rather than the original working state.
Real fix: cycling the NetworkManager connection forces a fresh DHCP
re-fetch and correctly restores DNS:
  sudo nmcli connection down netplan-enp1s0
  sudo nmcli connection up netplan-enp1s0
Confirmed working: Current DNS Server: 192.168.122.1 restored.

What changed vs what stayed the same:
Changed: enp1s0's DNS server (temporarily, via resolvectl dns), /etc/
hosts (permanently - stale example.com poison entries removed, this
is a genuine cleanup, not a regression).
Stayed the same: the underlying DHCP-provided DNS config, once
properly restored via nmcli cycling.

Automated or permanent version: fix/03-restore-resolver.sh implements
the proven nmcli-based recovery, not the unreliable resolvectl revert.

Detection gap / lesson generalized:
Two lessons stacked in this single lab:
1. Stale artifacts from earlier labs (the example.com /etc/hosts
   poison) can silently invalidate a later, unrelated test - always
   verify the actual resolution path taken (grep /etc/hosts, not just
   trust the final answer) before trusting a timing result.
2. A tool's own "revert"/"undo" command is not guaranteed to fully
   restore prior state - verify the restored state directly (this
   session: resolvectl status showing empty scopes) rather than
   trusting the revert command's exit code or its name's implication.
   Same root lesson as the DNS getent postmortem: command success is
   not evidence of correct resulting state.
