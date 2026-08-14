Date: 2026-08-13
Lab: Phase 3 (Transport) - TCP vs UDP verify script: two real defects found and fixed

Symptom (verbatim command and output):
Ran the pre-existing verify/01-tcp-vs-udp.sh on ubuntulab (Ubuntu
24.04). Script completed with no error, but printed no captured
packets for either the UDP or TCP section.

Root cause: two separate, independent defects compounding each other.

Defect 1 - DNS queries never reach the capture interface:
$ cat /etc/resolv.conf
  nameserver 127.0.0.53   (systemd-resolved's local stub resolver)
Plain `dig` queries are sent to 127.0.0.53 on loopback first - never
touching enp1s0 at all, so a capture on enp1s0 for udp port 53 can
legitimately see zero relevant traffic even when dig succeeds.
Confirmed directly:
$ sudo tcpdump -i lo -n udp port 53 -w /tmp/dns-test-lo.pcap &
  ... dig +short google.com ...
  Captured: 127.0.0.1.47255 > 127.0.0.53.53 - proves the query
  genuinely stays on loopback.

Defect 2 - killed capture process before it flushed to disk:
Even after bypassing the stub resolver (dig @<upstream-dns-server>,
forcing the query onto enp1s0), captures still intermittently showed
"0 packets captured" despite "N packets received by filter" -
meaning traffic crossed the interface and matched the filter, but
was never written to the pcap file before the process was killed.
Confirmed directly: using `sudo kill` (SIGTERM, no flush guarantee)
vs `sudo kill -INT` (SIGINT, same signal as Ctrl+C, tcpdump flushes
its buffer on exit) made the difference between an empty file and a
complete capture.

Evidence:

Isolated fix, manual test before touching the script:
$ sudo tcpdump -i enp1s0 -n udp port 53 -w /tmp/udp-verify2.pcap &
$ sleep 1; dig +short @192.168.122.1 google.com; sleep 2
$ sudo pkill -INT tcpdump; sleep 1
$ sudo tcpdump -r /tmp/udp-verify2.pcap -n
  2 packets captured - query and response, exactly as expected.

Fix applied to verify/01-tcp-vs-udp.sh:
1. Auto-detect upstream DNS server via resolvectl status, query it
   directly with dig @<server>, bypassing 127.0.0.53 entirely.
2. Added a process/file-existence verification loop before triggering
   traffic (same pattern as the handshake script fix), plus a longer
   settle time (sleep 2) after the DNS query specifically, since DNS
   exchanges are fast enough to complete and need time to flush.
3. Changed both kill calls from plain `kill` to `kill -INT`, ensuring
   tcpdump flushes its capture buffer before exiting.

Re-verified end to end after all fixes:
$ bash verify/01-tcp-vs-udp.sh
  UDP section: 2 packets captured (query + response) - matches script's
  own stated expectation exactly.
  TCP section: 12 packets captured - full handshake, HTTP GET/response,
  complete four-way FIN close.

Unrelated complication encountered mid-investigation: enp1s0 lost its
IPv4 address entirely due to a real DHCP ACD lease conflict (see
phase1-layer1-2/dhcp/postmortem/03-acd-conflict-lease-refused.md) -
this caused the script's own IFACE auto-detection to return empty
temporarily. Resolved separately via nmcli disconnect/connect before
this verify-script fix could be confirmed working.

What changed vs what stayed the same:
Changed: verify/01-tcp-vs-udp.sh - DNS query target, capture
verification loop, signal used to stop tcpdump.
Stayed the same: the actual TCP vs UDP mechanism being demonstrated -
never in question; both defects were entirely in the SCRIPT's ability
to observe and prove the mechanism, not the mechanism itself.

Fix applied: script corrected and re-verified working end to end.

Automated or permanent version of the fix: DONE - fix committed
directly into the script.

Detection gap: Same lesson as the handshake script and the earlier
NAT verify script this session - "0 packets captured" with no error
gives no indication of why, and can result from multiple unrelated
causes (wrong interface/traffic path, or a flush-timing race) that
look identical from the outside. Any future capture-based script
should be built with explicit verification and clean signal handling
from the start, not added retroactively after silent failures.
