Date: 2026-07-24
Lab: Phase 1 (Layer 1/2) - MTU investigation, large-transfer "hang" report

Symptom (verbatim command and output):
Reported: scp of large files from training-vm (Ubuntu 24.04) to
centos9 (CentOS Stream 9) hangs indefinitely; SSH sessions freeze on
large scrolling output. Small ping traffic reported as working fine.
No dmesg output on either host. Link UP/LOWER_UP on both.

Root cause: No fault present. Configured MTU matched on both
endpoints (1500), full-size unfragmented packets passed end-to-end
with 0% loss, and real large-file transfers completed successfully
with no stall. The reported symptom was never reproduced.

Evidence:
$ ip link show enp1s0 (training-vm, Ubuntu 24.04): mtu 1500
$ ip link show enp1s0 (centos9, CentOS Stream 9): mtu 1500
- both endpoints configured identically, no mismatch on paper.

$ ping -M do -s 1472 -c 4 192.168.122.207 (from training-vm)
4 packets transmitted, 4 received, 0% packet loss
- Don't-Fragment bit set, payload sized to hit the full 1500-byte
MTU exactly (1472 + 8 ICMP + 20 IP = 1500). Confirms full-size
packets traverse the path unfragmented and undropped.

$ scp /tmp/bigfile.bin training@192.168.122.207:/tmp/ (700MB file,
generated via dd if=/dev/zero of=/tmp/bigfile.bin bs=1M count=700)
Run twice: completed successfully both times (25.0MB/s and
13.6MB/s respectively) - no hang, no freeze, no stall.

What changed vs what stayed the same:
Nothing was changed on either host. No config touched. Interface
MTUs, routing, ARP state all remained as previously verified clean
earlier in tonight's sessions.

Fix applied:
None required - no fault existed to fix.

Automated or permanent version of the fix:
N/A - no fault present, nothing to automate. If this symptom is
reported again in the future, the correct first step is an
immediate measured baseline (DF-bit ping test + a real transfer)
before assuming which layer is responsible, per the detection gap
below.

Detection gap:
As with two earlier incidents tonight (phantom gateway fault,
phantom throughput fault), the reported symptom was never
independently measured before diagnosis began. A DF-bit ping test
and a real large-file transfer should be the first evidence
gathered for any "large transfers hang" report - both are fast,
low-effort, and immediately confirm or rule out an MTU-class fault
before spending time on tcpdump captures or deeper layers.

Process note (not a networking fault, logged separately):
First tcpdump capture attempt was invalid - tcpdump was stopped
(Ctrl+C) before the scp transfer was started, so the capture
recorded no transfer traffic. Lesson: start the capture, confirm
it's actively running, THEN start the action being observed -
never assume a background capture is running without checking.
