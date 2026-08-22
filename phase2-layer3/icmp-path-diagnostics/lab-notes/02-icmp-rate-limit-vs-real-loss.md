# Lab Notes -- ICMP Rate-Limiting vs. Real Packet Loss

Date: 2026-08-20

## Objective
Prove that ping/traceroute showing "packet loss" does not necessarily
mean the network path is broken -- a host or router may be deliberately
rate-limiting ICMP specifically, while forwarding real application
traffic (TCP/HTTP) with zero issue.

## Concept
Many hosts and routers rate-limit ICMP echo replies as a deliberate
security/load-protection measure -- not a fault. This produces a pattern
that looks identical to real packet loss in a naive ping/traceroute
reading, but the underlying path is completely healthy for real traffic.

## What Was Done
1. On ubuntulab, inserted an iptables rule rate-limiting ICMP echo
   replies to 1/second, burst 1:
   `sudo iptables -I INPUT 1 -p icmp --icmp-type echo-request -j DROP`
   `sudo iptables -I INPUT 1 -p icmp --icmp-type echo-request -m limit --limit 1/second --limit-burst 1 -j ACCEPT`
   (Rule order matters: inserted at the TOP of INPUT so it is evaluated
   before ufw's own unconditional ICMP ACCEPT rule -- see the separate
   ufw-precedence postmortem for why this mattered.)
2. From centos9, sent 10 pings at 0.2s intervals (5/sec) against the
   1/sec limit: `ping -c 10 -i 0.2 192.168.122.226`
   Result: 2/10 succeeded, 80% packet loss.
3. From centos9, tested real HTTP traffic to the same host, same
   moment: `curl -s -o /dev/null -w "HTTP status: %{http_code}, time: %{time_total}s\n" http://192.168.122.226`
   Result: HTTP 200, 0.07s -- succeeded cleanly, no issue at all.

## Evidence
ping:  10 packets transmitted, 2 received, 80% packet loss
curl:  HTTP status: 200, time: 0.070618s

Same host, same moment, same network path -- ICMP shows severe "loss,"
real application traffic is completely unaffected. This is direct proof
the degradation is isolated to ICMP handling, not the network path
itself.

## Real-World Relevance
This exact confusion is a common source of wasted troubleshooting time:
engineers chase a "broken link" based on ping/traceroute loss, when the
actual cause is deliberate ICMP deprioritization on a router or host
that is otherwise functioning perfectly. Always cross-check with real
application-layer traffic (curl, actual service connections) before
concluding a path is degraded based on ICMP alone.
