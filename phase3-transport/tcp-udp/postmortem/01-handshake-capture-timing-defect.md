Date: 2026-08-09
Lab: Phase 3 (Transport) - TCP handshake capture, real evidence plus a script timing defect found and fixed

Symptom (verbatim command and output):
Ran the pre-existing break/02-tcp-handshake-capture.sh on ubuntulab
(Ubuntu 24.04) to capture and decode a real TCP handshake to
example.com. The script completed with no error, but captured 0
packets - the resulting pcap was empty.

Root cause: The script started tcpdump in the background, waited a
fixed sleep 2, then triggered curl - with no verification step
confirming tcpdump was actually listening before triggering traffic.
Same class of timing defect diagnosed earlier this session in the NAT
verify script - a fixed sleep is not a reliable substitute for
actually checking the capture is running.

Evidence:

Script run as-is, before any fix:
$ bash break/02-tcp-handshake-capture.sh
  0 packets captured, 0 packets received by filter

Isolated actual connectivity first (ruled out a network problem):
$ curl -sv -o /dev/null http://example.com --max-time 5
  HTTP/1.1 200 OK - confirmed clean, real connectivity.

Manual capture with an explicit verification step, proving the
mechanism itself works when timing is handled correctly:
$ sudo tcpdump -i enp1s0 -n host <ip> and tcp port 80 \
    -w /tmp/manual-test.pcap &
$ jobs   # confirmed "Running" BEFORE triggering traffic
$ curl -s -o /dev/null http://example.com
$ sudo pkill tcpdump && sudo tcpdump -r /tmp/manual-test.pcap -n
  12 packets captured - complete handshake, HTTP GET/response, clean
  four-way FIN close. SYN seq 2066187395, matching SYN-ACK ack
  2066187396 (seq+1) - confirms the seq/ack math the script itself
  asks the user to verify.

Fix applied to the script (break/02-tcp-handshake-capture.sh):
1. sudo rm -f the old pcap before starting - the original had a
   non-sudo rm -f, which silently failed (Operation not permitted)
   against a root-owned file left over from a prior sudo run,
   letting a stale file mask whether the new capture actually opened
   fresh.
2. Replaced the fixed sleep 2 with a polling loop (up to 20 x 0.2s)
   that checks BOTH the pcap file exists AND the tcpdump process is
   genuinely alive (kill -0) before proceeding to trigger traffic.

Re-ran after the fix:
$ sudo rm -f /tmp/tcp-handshake.pcap   # cleared the stale root-owned
                                          file first
$ bash break/02-tcp-handshake-capture.sh
  "Capture confirmed running (pid 3506)." printed BEFORE curl ran.
  10 packets captured, 12 received by filter (the 2 missing were
  in-flight FIN/ACK packets that arrived just after the capture was
  killed - a minor, expected timing edge, not the original defect).
  Full handshake, HTTP exchange, and start of FIN close all correctly
  captured and decoded.

What changed vs what stayed the same:
Changed: break/02-tcp-handshake-capture.sh - added a real verification
step, fixed the non-sudo rm bug. Files also renumbered from 02b/02c
to 01/02 to match this repo's local convention (separate change).
Stayed the same: the actual TCP handshake mechanism - never broken,
proven working correctly throughout via the manual capture.

Fix applied: the capture script itself was corrected and re-verified
working, not just documented as a known issue.

Automated or permanent version of the fix: DONE - the fix is now
committed directly into break/02-tcp-handshake-capture.sh itself, so
future runs of this script no longer have the timing race.

Detection gap: A script completing with no error and reporting "0
packets captured" gave no indication of why - same failure signature
as the NAT verify script earlier this session. Lesson generalized:
any capture-based script should explicitly confirm the capture is
active (process check, not just file existence, since a stale file
can exist without a live capture writing to it) before triggering the
traffic it's meant to observe.

## Fix applied and partial result (2026-08-15)
Applied the identified fix: verify tcpdump is running (poll loop) before
triggering traffic. This alone was insufficient — testing revealed a
SECOND, distinct bug: DNS round-robin (dig and curl each resolving
independently) could return DIFFERENT IPs, causing the capture filter
to watch the wrong address entirely. Confirmed via repeated `dig`
queries returning alternating IPs (104.20.23.154 / 172.66.147.243).
Fixed by pinning curl to the exact resolved IP with `--resolve`.

Result: capture now reliably gets packets (8 captured vs 0 before), but
STILL misses the opening SYN/SYN-ACK — the connection completes faster
than the verification loop's ~4-second max wait allows tcpdump to fully
attach. Real, honest remaining gap: even "confirmed running" via
process-alive + file-exists checks isn't sufficient proof the capture
is ready to catch the very first packets of a fast local connection.
Not resolved tonight — a possible next step is adding a short mandatory
settle delay AFTER confirming the process is running, or using a
capture-ready signal more precise than PID/file existence.
