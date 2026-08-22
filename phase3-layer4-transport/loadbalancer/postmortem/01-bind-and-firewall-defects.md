Date: 2026-08-22
Lab: Phase 3 (Transport) - nginx load balancer, real evidence plus two
production-shaped defects found via cross-host testing, not localhost assumption.

Symptom (verbatim command and output):
Ran the pre-existing break/08-loadbalancer-setup.sh on ubuntulab
(Ubuntu 24.04). Script completed with no error - nginx -t passed,
reload succeeded, round-robin visibly worked when tested from
localhost. Nothing in the script's own output indicated a problem.

Root cause 1 - backends bound to all interfaces:
python3 -m http.server 8081/8082 binds to 0.0.0.0 by default unless
-b is passed. The script never passed -b, so both backends were
directly reachable from the network - completely bypassing nginx,
with no LB logic, no centralized logging, no single point of control.

Root cause 2 - UFW never given a rule for the LB's own port:
nginx correctly listened on 0.0.0.0:8090 (confirmed via ss), but UFW's
allow-list only covered 80, 22, and 5201/tcp. Port 8090 was never
added. The load balancer itself was unreachable from any other host
on the network, despite every internal component being correctly
configured - a defect invisible from ubuntulab itself, since UFW's
INPUT rules don't block traffic that never leaves the box.

Root cause 3 - the pre-existing verify script cannot detect either
defect above:
fix/08-loadbalancer-verify.sh (moved to verify/01-loadbalancer-verify.sh
this session) only checks ss, systemctl status, and curl - all run
against localhost:8090. Neither the 0.0.0.0 bind issue nor the missing
UFW rule would ever surface from running this script as-is. A "verify"
script that cannot detect the two real defects found this session is
itself a defect - false confidence, not verification.

Evidence:

Confirmed backends bound to all interfaces (before fix):
$ sudo ss -tulnp | grep -E "8081|8082"
  tcp LISTEN 0.0.0.0:8081 ...
  tcp LISTEN 0.0.0.0:8082 ...

Fix 1 applied: killed both http.server processes, relaunched with
-b 127.0.0.1. Confirmed against kernel state, not process claims:
$ sudo ss -tulnp | grep -E "8081|8082"
  tcp LISTEN 127.0.0.1:8081 ...
  tcp LISTEN 127.0.0.1:8082 ...

Cross-host verification from centos9 (192.168.122.207) against
ubuntulab (192.168.122.226):
$ nc -zv 192.168.122.226 8081
  Ncat: TIMEOUT.
Confirmed this was "no listener," not "firewall drop," by checking
ss on ubuntulab first (showed 127.0.0.1 only, no external socket to
drop from) - the two causes of a TCP timeout require different
diagnostic commands to distinguish, and ss alone was sufficient here.

Root cause 2 evidence - LB port itself unreachable cross-host despite
correct internal config:
$ nc -zv 192.168.122.226 8090
  Ncat: TIMEOUT.
$ sudo ss -tulnp | grep 8090   # on ubuntulab
  tcp LISTEN 0.0.0.0:8090 ... (nginx)   # listener confirmed present
$ sudo ufw status
  80/tcp ALLOW, 22 ALLOW, 5201/tcp ALLOW - 8090 absent entirely

Fix 2 applied:
$ sudo ufw allow from 192.168.122.0/24 to any port 8090 proto tcp
Scoped to the lab subnet, not opened globally - no reason to expose
8090 to the world for a lab load balancer.

Re-verified full chain cross-host from centos9:
$ nc -zv 192.168.122.226 8090
  Ncat: Connected to 192.168.122.226:8090.
$ for i in {1..6}; do curl -s http://192.168.122.226:8090/; done
  Response from Server 1 / Server 2 alternating cleanly across all 6
  requests - round-robin confirmed working end to end, through the
  firewall, to loopback-only backends.

What changed vs what stayed the same:
Changed: backend bind address (0.0.0.0 -> 127.0.0.1), UFW rule set
(added 8090/tcp scoped to lab subnet). Also added proxy_http_version
1.1 to the nginx config as a secondary change (see open item below -
its effect was not isolated from http.server's own default protocol,
so it's documented as a change made, not a confirmed fix for a
specific symptom). Verify script relocated from fix/ to verify/ and
renumbered to match repo convention, content not yet rewritten to add
cross-host checks.
Stayed the same: nginx config's core proxy_pass / upstream block,
round-robin behavior itself - never broken, worked correctly from the
first run onward once traffic could actually reach it.

Fix applied: both defects corrected directly on the running lab and
re-verified with cross-host evidence, not just documented as known
issues.

Automated or permanent version of the fix: NOT YET DONE. The bind
flag and UFW rule are currently manual, one-off commands applied to
this session's running processes - break/08-loadbalancer-setup.sh
itself still contains the original 0.0.0.0 bind and still ships no
UFW rule. The script needs to be edited directly (same treatment
given to break/02-tcp-handshake-capture.sh in tcp-udp/) so future runs
don't reintroduce either defect. verify/01-loadbalancer-verify.sh also
needs a cross-host check added (e.g. accept a remote host arg and run
nc -zv from there, or document that it must be run from a second host
to be meaningful) so it can actually catch what it currently misses.

Detection gap: A script that reports success (nginx -t passes, reload
succeeds, curl from localhost returns a response) gave zero indication
that the service was unreachable from the actual network it was meant
to serve. Lesson generalized: any service-standup script tested only
from localhost is unverified for its actual purpose. Cross-host testing
(a second real host, not just a second terminal on the same box) is
the only thing that caught either defect here.

## Open item - not resolved this session (2026-08-22)
HTTP/1.0 vs HTTP/1.1 observed in backend access logs: requests proxied
through nginx logged as HTTP/1.0, requests sent directly to a backend
logged as HTTP/1.1. Two possible causes, not yet isolated: nginx's own
proxy_http_version default (1.0) vs http.server's own declared default
protocol (also 1.0 per --help output). proxy_http_version 1.1 was added
to the nginx config as part of this session's fix, but the change was
never tested in isolation (config reverted / A-B tested) to confirm it
was the actual cause rather than a red herring. Possible interesting
side-finding either way: protocol version in a backend's own log could
serve as an incidental signal for LB-bypass detection - worth a
dedicated follow-up test, not stated as confirmed here.
