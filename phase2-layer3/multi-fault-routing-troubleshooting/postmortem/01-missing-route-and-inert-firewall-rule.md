# Postmortem

Date: 2026-08-29

Lab: Phase 2 -- Multi-Fault Capstone: Missing Return Route + Wrong-Chain Firewall Rule

## Symptom (verbatim command and output)

Command: sudo ip netns exec client ping -c 3 10.0.2.2
Output:
PING 10.0.2.2 (10.0.2.2) 56(84) bytes of data.
--- 10.0.2.2 ping statistics ---
3 packets transmitted, 0 received, 100% packet loss, time 2052ms

## Root Cause

Two independent, simultaneous faults were present:

1. server's routing table was missing its return route to client's
   subnet (10.0.1.0/24 via 10.0.2.1). With no matching route and no
   default route, the kernel's route lookup for any reply destined to
   10.0.1.2 failed outright -- the reply was never transmitted at all.

2. A firewall rule on router1 (iptables -I OUTPUT -p icmp --icmp-type
   echo-reply -j DROP) was placed on the wrong chain. OUTPUT only
   matches traffic router1 generates itself; the echo-reply being
   relayed from server to client passes through the FORWARD chain
   instead, so this rule never matched any real traffic and had zero
   effect on the incident.

## Evidence

- tcpdump -i any -n icmp inside router1, captured WHILE reproducing
  the failure, showed the echo-request arriving from client and being
  correctly forwarded toward server -- proving the outbound path
  healthy and isolating the fault to the return path, before any
  configuration was touched.
- ip route inside server showed only the connected 10.0.2.0/24 route
  present -- direct proof of the missing return route, no assumption
  required.
- After fixing the route, ping succeeded immediately (0% loss),
  revealing the second fault had never actually been active.
- iptables -L OUTPUT -v -n --line-numbers on router1 showed the
  echo-reply DROP rule at 0 pkts / 0 bytes even after real matching
  traffic had crossed the router -- direct proof the rule was inert,
  confirmed BEFORE removing it rather than assumed.

## What Changed vs What Stayed the Same

Changed: server's routing table (route added back), router1's OUTPUT
chain (inert rule removed).

Stayed the same: the underlying topology, veth wiring, and IP
forwarding configuration on router1 were correct throughout and never
needed modification -- both faults were configuration-level, not
structural.

## Fix Applied

sudo ip netns exec server ip route add 10.0.1.0/24 via 10.0.2.1
sudo ip netns exec router1 iptables -D OUTPUT -p icmp --icmp-type echo-reply -j DROP

Verified with a full re-test (ping -c 3, 0% loss) after both fixes
were applied.

## Automated or Permanent Version of the Fix

break/01-missing-route-and-wrong-chain.sh and
fix/01-restore-route-and-remove-inert-rule.sh -- reproduce this exact
two-fault scenario and its resolution on demand, for repeated practice
without needing to remember the specific commands from scratch.

## Detection Gap

Fixing one symptom and immediately declaring an incident resolved,
without checking for other unrelated changes still present, risks
missing a second fault that simply wasn't triggered by the specific
test just run. In this case the second fault happened to be harmless
by accident (wrong chain made it inert) -- in a different scenario, an
unnoticed second fault could resurface under different traffic
patterns after the incident was already marked closed.

Separately: a firewall rule's mere presence in a chain listing is not
evidence it is having any effect. Always check hit counters
(iptables -L -v -n) before trusting that a rule is doing its intended
job, especially on a routing device where INPUT, OUTPUT, and FORWARD
serve three genuinely distinct purposes.
