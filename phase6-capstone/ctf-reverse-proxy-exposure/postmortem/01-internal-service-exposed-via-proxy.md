Date: 2026-09-15
Lab: Phase 6 Capstone - HTB/CTF-style exercise, attacker/client (centos9)
vs deliberately vulnerable target (ubuntulab)

Setup: normal target architecture is client -> ubuntulab:8090 -> nginx
-> 127.0.0.1:8081/8082 (loopback-only backends). A deliberate
vulnerability was introduced: an additional nginx location,
/internal/, proxying to a third loopback-only service on
127.0.0.1:9000 - simulating a real internal admin panel that should
never be reachable from the network.

Reconnaissance (from centos9, attacker/client role):
$ nmap -sn 192.168.122.0/24            -> target found: .226
$ nmap -p- 192.168.122.226              -> 22 open, 80 open, 5201
  closed, 8090 open, rest filtered
$ nmap -sV -p 22,80,8090 192.168.122.226
  22 OpenSSH 9.6p1, 80 nginx, 8090 nginx
$ curl -i http://192.168.122.226/       -> default nginx welcome page
$ curl -i http://192.168.122.226:8090/  -> "Response from Server 1/2"
  (identified 8090 as the more interesting, custom service)
$ common-path enumeration (/admin /internal /management /status
  /metrics etc.)                        -> all 404 initially

Architecture discovery (target-side inspection):
$ sudo cat /etc/nginx/sites-enabled/loadbalancer.conf
  confirmed: upstream backend_pool { 127.0.0.1:8081; 127.0.0.1:8082; }
$ sudo ufw status numbered
  8090/tcp ALLOW IN 192.168.122.0/24
Correctly treated "proxy is network-reachable, backends are loopback-
only" as an OBSERVATION about attack surface, not an automatic
vulnerability claim - escalated to a real finding only after empirical
proof.

Deliberate vulnerability introduced (target-side, for the exercise):
added `location /internal/ { proxy_pass http://127.0.0.1:9000/; }` to
the nginx config, validated (`nginx -t`), reloaded.
Real, unplanned incident during setup: a config backup was
accidentally placed inside sites-enabled, causing nginx to load it as
live config (`nginx -t` reported "duplicate upstream backend_pool").
Corrected by moving backups outside sites-enabled - documented as a
real configuration-management lesson: never store backup nginx config
files inside a directory nginx auto-includes.

Internal service stood up (target-side): a loopback-only HTTP server
on 127.0.0.1:9000 serving "INTERNAL ADMIN PANEL - NOT FOR EXTERNAL
ACCESS." First test of the new proxy route returned 502 - investigated
and found the internal service wasn't running yet (`ss -lntp | grep
:9000` empty), started it, confirmed local 200 OK.

Vulnerability validated (from centos9, real cross-host proof, both
directions tested):
$ curl -i http://192.168.122.226:8090/internal/
  200 OK, "INTERNAL ADMIN PANEL - NOT FOR EXTERNAL ACCESS"
$ curl -i --max-time 3 http://192.168.122.226:9000/
  Connection timed out
This is the actual proof of the vulnerability: direct access to the
loopback-bound service is genuinely blocked (confirming the backend's
own binding is correct), but the SAME service is fully reachable
through the reverse proxy from an external client - the isolation
boundary was defeated indirectly, not by a backend misconfiguration.

Remediation: removed the /internal/ location block, validated
(`nginx -t`), reloaded (`systemctl reload nginx`), stopped and removed
the temporary internal service and its directory, removed temporary
nginx backup files.

Verification (from centos9, post-fix):
$ curl -i --max-time 3 http://192.168.122.226:8090/internal/ -> 404
$ ss -lntp | grep :9000 (target-side)                          -> no listener
$ curl -s http://192.168.122.226:8090/  -> normal "Response from
  Server 1/2" load-balancer behavior restored

What changed vs what stayed the same:
Changed: nginx config (added then removed the vulnerable location
block), a temporary service stood up then fully removed.
Stayed the same: the real backend pool (8081/8082) and its loopback-
only binding - never touched, remained correct throughout; the
vulnerability was entirely in the proxy layer, not the backend's own
security posture.

Fix applied: yes, fully removed and independently re-verified from
the attacker/client host, not just locally on the target.

Detection gap / lesson generalized: a service bound to 127.0.0.1 is
NOT automatically isolated from the network if anything else on that
same host can act as a proxy to it. The correct security boundary has
to be evaluated across the full request path (who can reach the
frontend -> what paths it exposes -> where those paths route -> what
they expose), not just at the backend's own socket binding. This is a
real, common class of misconfiguration in reverse-proxy architectures.
