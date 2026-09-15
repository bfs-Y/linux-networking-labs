Date: 2026-09-15
Lab: Phase 6 Capstone - Multi-Fault Networking Incident (blind diagnosis,
no hints on fault type or count, cold investigation)

Environment:
- ubuntulab (Ubuntu 24.04) - affected server, load balancer (nginx on
  8090, backends on 127.0.0.1:8081/8082)
- centos9 (CentOS 9) - independent client, used for end-to-end proof
- libvirt hypervisor - default network, 192.168.122.0/24, DHCP pool
  .2-.254, gateway/DHCP server 192.168.122.1

Symptom (as given, no further detail): "the application was unreachable."

Fault 1 - DHCP/ACD address rejection:
$ ip -br addr / ip route
  enp1s0 link-up, no IPv4 address, no usable default route (only the
  Docker route present)
$ nmcli device show enp1s0 / connection show netplan-enp1s0
  ipv4.method: auto (DHCP), but no active IPv4 address or gateway
$ sudo journalctl -u NetworkManager --since "5 minutes ago"
  repeated: "new lease, address=192.168.122.226, acd conflict"
$ sudo tcpdump -n -i enp1s0 -vvv 'udp port 67 or 68'
  Discover -> Offer(.226) -> Request -> ACK(.226) -> Decline ("acd failed")
Root cause of the ACD result itself NOT conclusively identified - ARP
testing (arping -D, ip neigh show, tcpdump arp) found no other host
actively claiming .226 at the time of investigation, and the libvirt
DHCP lease table (virsh net-dhcp-leases default) did not show .226
assigned elsewhere. Correctly NOT claimed as a proven duplicate-IP
condition - evidence doesn't support that specific claim, even though
ACD is what rejected the lease.

OPEN ITEM: this same host (ubuntulab, IP .226) has a prior, real ACD
conflict documented in phase1-layer1-2/dhcp/postmortem/03-acd-conflict-
lease-refused.md. Not yet confirmed whether this is the same underlying
recurring cause or a fresh, unrelated instance - worth cross-checking
against that postmortem's root cause before considering this fully
closed. If recurring, that's a more significant systemic finding than
a one-off.

Fix (network): manually proved the network/gateway path was healthy
independent of NetworkManager (`ip addr add .226/24`, pinged gateway,
0% loss), removed the manual address, then reset NetworkManager
(`nmcli device reapply/disconnect/connect enp1s0`) - DHCP then
successfully installed .226/24 and the default route cleanly.

Fault 2 - missing backend processes:
$ ss -lntp | grep -E ':8081|:8082|:8090'
  nginx listening on 8090; nothing on 8081/8082
$ curl -I http://127.0.0.1:8090
  502 Bad Gateway
$ sudo nginx -T | grep -A5 -B2 '8081\|8082'
  confirmed upstream config: 127.0.0.1:8081, 127.0.0.1:8082
Backend directories/files existed but no process was running - simple
missing-service condition, first of two independent backend problems.

Fault 3 - backend processes running but returning empty replies (found
AFTER fixing fault 2, not before - correctly kept investigating instead
of declaring victory once ports showed listening):
$ curl -I http://127.0.0.1:8081  ->  "Empty reply from server"
$ tail /var/log/nginx/error.log  ->  "upstream prematurely closed connection"
$ sudo strace -p <pid> -e trace=network,read,write -f
  recvfrom() received the GET request, then write(2, ...) -> EIO,
  then shutdown() - the process was failing specifically on writing
  its own access-log line to stderr, not on handling the request itself
$ sudo readlink /proc/<pid>/fd/2
  "/dev/pts/0 (deleted)" and "/dev/pts/1 (deleted)"
Root cause: the backend Python processes' stderr was attached to a
pseudo-terminal that no longer existed (deleted out from under them,
likely from how they were originally launched/backgrounded in an
earlier interactive session). Every request attempt triggered a
logging write to a dead fd, got EIO, and the process closed the
connection without ever sending an HTTP response - a completely
different failure mode from "not running" (fault 2), invisible from
`ss` alone since the port WAS genuinely listening.

Fix (backend): killed the defective processes, relaunched with
explicit persistent redirection (`nohup ... >/tmp/serverN.log 2>&1 &`)
instead of relying on an interactive terminal's fds surviving.

Verification (full chain, not just local):
$ curl -I http://127.0.0.1:8081 / :8082 / :8090  -> all 200 OK
$ from centos9: curl -I http://192.168.122.226:8090  -> HTTP/1.1 200 OK

What changed vs what stayed the same:
Changed: enp1s0's IPv4 config (via NM reset), the two backend
processes (killed and relaunched with proper fd redirection).
Stayed the same: nginx config itself (never touched - correctly
identified nginx was a healthy pass-through, not the fault, by
tracing the 502 to its actual upstream rather than assuming nginx
itself was broken).

Fix applied: yes, both independent faults resolved and independently
re-verified; end-to-end proof came from a genuinely separate host
(centos9), not just localhost on the affected server.

Automated or permanent version of the fix: NOT YET DONE. Backend
processes are still manually launched, interactive-adjacent (nohup +
background, not a real systemd unit) - a recurrence of the same
deleted-pty class of failure is plausible under the current launch
method. A real permanent fix would be a systemd service unit for each
backend, which manages its own fd lifecycle independent of any
terminal session.

Detection gap: a listening TCP port was treated as sufficient evidence
of health during initial triage, and correctly revised only after a
502 and then an empty-reply symptom forced deeper investigation
(strace). The general lesson, consistent with every process-verification
lesson from earlier in this repo: "the port is listening" and "the
service is loudly connected" are not proof of a healthy dependency
chain - only an actual successful request/response cycle is.
