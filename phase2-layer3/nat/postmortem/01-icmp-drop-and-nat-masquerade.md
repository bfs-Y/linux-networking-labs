Date: 2026-07-07 (scripts written), re-verified 2026-08-01
Lab: Phase 2 (Layer 3) - NAT: ICMP drop/restore and MASQUERADE removal

Symptom (verbatim command and output):
Two separate break/fix scenarios exist under this topic.

Scenario 1 - outbound ICMP silently dropped:
$ sudo iptables -I OUTPUT -d 8.8.8.8 -p icmp -j DROP
$ ping -c 2 8.8.8.8
2 packets transmitted, 0 received, 100% packet loss

Scenario 2 - NAT/MASQUERADE rule removed:
$ sudo iptables -t nat -F POSTROUTING
$ sudo docker exec nat-test curl -sv -o /dev/null http://example.com --max-time 5
* Resolving timed out after 5001 milliseconds

Root cause:
Scenario 1: an explicit iptables OUTPUT rule dropped outbound ICMP to a
specific destination - deliberate, direct, easy to find in the ruleset.
Scenario 2: flushing the NAT POSTROUTING chain removed the MASQUERADE
rule that rewrites container-sourced traffic to the host's real IP.
Without it, the container's internal IP (172.17.0.2, an RFC1918
non-routable address) was used as the source for ALL outbound traffic,
including DNS queries - so DNS resolution itself failed, not just the
HTTP request. This is a more complete failure than the original script
comments anticipated ("traffic will leak its internal IP" implies
traffic still flows, just with the wrong source - in practice, nothing
useful reached the container at all, since replies to an unroutable
source address never come back).

Evidence:

Scenario 1, re-verified end to end (2026-08-01):
$ bash break/01-traffic-drop.sh
  Rule added, confirmed via iptables -L OUTPUT -n -v; ping 100% loss.
$ bash fix/01-traffic-restore.sh
  Rule removed, confirmed clean; ping 2/2 received, 0% loss.
Clean, correct, matches the script's documented behavior exactly.

Scenario 2, re-verified end to end (2026-08-01), with real complications:
$ bash break/02-nat-masquerade-missing.sh
  Flushed nat POSTROUTING as designed.
$ bash verify/02-nat-verify.sh
  FIRST RUN: failed for an unrelated reason - a stale, stopped
  container (nat-test) from a prior session caused "container is not
  running" and 0 packets captured. Not a NAT fault - a stale test
  fixture. Cleaned up with: sudo docker rm nat-test
  SECOND RUN (fresh container): still 0 packets captured by the
  script's own tcpdump-based check, despite the container genuinely
  being unable to reach the internet. The script's packet-capture
  approach did not reliably prove the fault - likely a timing issue
  (its `sleep 1` before triggering traffic, combined with a DNS
  resolution failure that never even reaches the HTTP request the
  capture was watching for).
Manual verification (more reliable than the script's own check):
$ sudo docker exec nat-test curl -sv -o /dev/null http://example.com --max-time 5
  * Resolving timed out after 5001 milliseconds
  Confirms: complete outbound failure, not just wrong source IP.

$ bash fix/02-nat-masquerade-restore.sh
  Restored MASQUERADE on bond0 (correctly auto-detected the current
  default-route interface, which is now bond0 following this
  session's earlier bonding work - not enp1s0/enp7s0 individually).
$ sudo docker exec nat-test curl -sv -o /dev/null http://example.com --max-time 5
  HTTP/1.1 200 OK, full response from example.com - confirmed genuine
  end-to-end restoration, real DNS resolution and HTTP transaction
  completed successfully.

What changed vs what stayed the same:
Changed: OUTPUT chain gained/lost one DROP rule (scenario 1); nat
POSTROUTING chain was flushed and MASQUERADE re-added (scenario 2).
A stale nat-test container from an earlier session was removed and
recreated fresh during this re-verification.
Stayed the same: host networking config otherwise, gateway, other
iptables chains/tables.

Fix applied:
Scenario 1: iptables -D to remove the specific DROP rule.
Scenario 2: iptables -t nat -A POSTROUTING -o <iface> -j MASQUERADE,
using dynamic interface detection rather than a hardcoded name -
correctly adapted to bond0 without any script changes needed.

Automated or permanent version of the fix:
Both scripts already exist and are correctly automated (break/fix
pairs). Real gap found: verify/02-nat-verify.sh's packet-capture
based proof did not reliably demonstrate the fault or the fix on
either run - it should be revised to also perform a direct
docker exec curl check (as done manually here) rather than relying
solely on a timed tcpdump capture, which is fragile to timing and to
DNS-resolution failures preventing the traffic it's trying to catch.

Detection gap:
The verify script's own reliability is the real finding here: it
produced "0 packets captured" both when a stale container blocked the
test entirely AND when a genuine NAT fault was present - the same
output for two different root causes. A verify script that can't
distinguish "test never ran" from "test ran and failed" is a real gap;
future revision should add an explicit pre-check (is the container
actually running?) and a direct connectivity check independent of the
packet capture, so failure modes are distinguishable.

## Follow-up finding (2026-08-01, verify script rewrite)
Rewrote verify/02-nat-verify.sh to use a direct connectivity check
instead of packet capture. During testing, found:
- alpine's busybox wget failed against a hostname ("bad address") even
  though DNS resolution itself succeeded via nslookup — tool-specific
  quirk, not a real fault.
- wget against a raw IP (93.184.216.34) genuinely timed out.
- iptables -t nat -L POSTROUTING -n -v confirmed MASQUERADE rule IS
  present and has matched 4 packets — NAT rewriting is happening.
- This means the actual failure is downstream of NAT (rewriting works),
  likely a FORWARD chain or firewall rule blocking outbound HTTP after
  translation. NOT YET ROOT-CAUSED — stopped here for tonight, logged
  as an open, real finding rather than a closed conclusion.
Next session: check `iptables -L FORWARD -n -v` and `nft list ruleset`
for anything blocking outbound traffic post-NAT.
