# Postmortem

Date: 2026-08-20

Lab: Phase 2 -- ICMP Rate-Limiting vs. Real Packet Loss

## Symptom (verbatim command and output)

Command: ping -c 10 -i 0.2 192.168.122.226 (from centos9)
Output:
10 packets transmitted, 2 received, 80% packet loss, time 1864ms
rtt min/avg/max/mdev = 0.728/0.770/0.813/0.042 ms

## Root Cause

An iptables rule was deliberately inserted on ubuntulab to accept only
1 ICMP echo-request per second, dropping any faster than that. Sending
10 pings at 5/second against a 1/second limit produced the observed
~80% loss. This is not a network fault -- it is expected, deliberate
behavior of the rate-limit rule.

## Evidence

Same host, same moment, two different protocols:
- ping (ICMP):  80% packet loss
- curl (HTTP):  HTTP status 200, 0.070618s, zero issue

The contrast between these two results, gathered within the same
testing window against the same destination, is direct proof that the
degradation is isolated to ICMP specifically, not the underlying network
path or the host's ability to forward real traffic.

## What Changed vs What Stayed the Same

Changed: ICMP echo-request handling on ubuntulab, from unlimited
(ufw's own default ACCEPT) to rate-limited (1/sec via inserted
iptables rules).

Stayed the same: HTTP service on port 80 continued functioning
normally and was never affected by the ICMP-specific rule.

## Fix Applied

phase2-layer3/icmp-path-diagnostics/fix/02-remove-icmp-rate-limit.sh --
removes the inserted rate-limit rules via iptables -D, restoring
unlimited ICMP echo-request handling.

## Automated or Permanent Version of the Fix

The break/fix pair itself is the reusable, on-demand version -- run
break/02-icmp-rate-limit.sh to reproduce the scenario for practice,
fix/02-remove-icmp-rate-limit.sh to restore normal behavior.

## Detection Gap

Ping/traceroute-based "packet loss" is not, on its own, proof of a
broken network path. Before escalating a suspected network fault based
on ICMP loss alone, always cross-check with a real application-layer
test (curl, an actual service connection) to the same destination. If
real traffic succeeds while ICMP shows loss, the most likely explanation
is deliberate ICMP rate-limiting or deprioritization, not a genuine
path failure.
