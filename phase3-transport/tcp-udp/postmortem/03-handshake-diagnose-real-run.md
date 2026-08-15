Date: 2026-08-13
Lab: Phase 3 (Transport) - TCP handshake failure diagnosis, real run against an unreachable target

Symptom (verbatim command and output):
Ran fix/02-tcp-handshake-diagnose.sh on ubuntulab (Ubuntu 24.04) for
the first time against its default target, neverssl.com, to confirm
the diagnostic workflow itself works correctly end to end.

Root cause: N/A - this was a real diagnostic run, not a fault in
tooling. The script performed correctly and produced a genuine,
evidence-supported conclusion about the target's reachability.

Evidence:

Step 1-2 - baseline vs target comparison:
$ curl (baseline) example.com -> succeeded, confirms local machine/
  VM/gateway/ISP/DNS all healthy.
$ curl (target) neverssl.com -> failed. Correctly isolated the fault
  to the target side, not the local setup.

Step 3 - captured the actual failed handshake attempt:
$ tcpdump ... host 34.223.124.45 and tcp
  4 SYN packets, same seq (774464016), retransmitted at ~1-second
  intervals (TCP's own retransmission backoff) - ZERO SYN-ACK replies
  ever received. This is the exact signature the script itself
  documents: "target is dropping/ignoring connections."

Step 4 - traceroute to the target:
  Reached real backbone infrastructure (154.54.x.x - Cogent
  Communications network) through hop 22, responding normally.
  Hops 16, 23, and 25-30 (the majority of the back half) show "* * *".
  The actual destination (34.223.124.45) is NEVER reached in any of
  the 30 hops.

Interpretation, distinguishing this from a healthy silent-hop pattern
(as seen with 8.8.8.8 in the Phase 2 icmp-path-diagnostics topic):
in that case, silent hops were sandwiched between hops that DID
respond, including the final destination - proof traffic passed
through cleanly. Here, the destination itself is never reached at
all, and real SYN packets sent as part of an actual connection
attempt (not just diagnostic probes) get zero replies. Combined,
this evidence converges on the script's own conclusion: a firewall
or dead host near the destination, not a healthy unresponsive router.

What changed vs what stayed the same:
Nothing changed - this was entirely a read-only diagnostic run.

Fix applied: N/A - the "fault" here is external, on neverssl.com's
side or a firewall in front of it, entirely outside this host's
control. Nothing to fix locally.

Automated or permanent version of the fix: N/A. This confirms
fix/02-tcp-handshake-diagnose.sh works correctly as a real diagnostic
tool - no changes needed to the script itself.

Detection gap: N/A - the script's own documented interpretation
guide ("only SYN, no SYN-ACK = target dropping connections" /
"traceroute dies with * * * near the end = firewall or dead host")
correctly matched the real evidence gathered, on the first real run,
with no prior tuning needed.
