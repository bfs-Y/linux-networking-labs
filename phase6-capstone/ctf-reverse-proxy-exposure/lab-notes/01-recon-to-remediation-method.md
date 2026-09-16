# Lab Notes: CTF-Style Reverse Proxy Exposure - Full Method
Topic: Recon -> exploitation validation -> impact proof -> remediation -> re-verification

--- THE REPEATABLE METHOD, IN ORDER ---
Recon -> Port scan -> Service detection -> HTTP enumeration ->
Architecture discovery -> Security hypothesis -> Controlled validation
-> Impact proof -> Root cause -> Remediation -> Attacker-side
verification.
Each stage exists to avoid two real mistakes: acting on a guess before
proving it, and declaring a fix complete without proving it from the
same vantage point an attacker would actually use.

--- UNPRIVILEGED HOST DISCOVERY BEFORE ANYTHING ELSE ---
`nmap -sn <subnet>` first - confirm the target actually exists and is
reachable before spending time on a full port scan against a
potentially wrong or dead address.

--- FULL PORT SCAN, THEN VERSION DETECTION, SEPARATELY ---
`nmap -p-` first (find every open port, no assumptions about what
"should" be running), THEN `-sV` on the specific ports found (identify
what's actually there). Doing both in one pass on a huge port range is
slower and less necessary than scoping -sV to only the ports already
confirmed open.

--- COMPARING SIMILAR SERVICES TO FIND THE INTERESTING ONE ---
Both port 80 and port 8090 ran nginx, but a plain curl comparison
immediately showed one was a default install (generic welcome page)
and the other was a real, custom application (load-balanced backend
responses) - the more customized/non-default service is generally the
one worth deeper investigation first.

--- ARCHITECTURE DISCOVERY BEFORE FORMING A SECURITY HYPOTHESIS ---
Reading the actual nginx config and firewall rules on the target
(when accessible) turns guessing into evidence-based hypothesis
forming. The real observation here - "the frontend is network-
reachable, the backends are loopback-only" - is not itself a finding;
it's the setup that makes a specific hypothesis (proxy might expose
loopback services) worth testing.

--- VALIDATE BEFORE ESCALATING TO "THIS IS A VULNERABILITY" ---
An architectural observation is not a proven vulnerability until
empirically demonstrated. The actual proof here required TWO tests,
not one: confirming the internal service is genuinely unreachable
DIRECTLY (proves the backend's own binding is correctly restrictive),
and confirming it IS reachable THROUGH the proxy (proves the bypass
is real). Either test alone is insufficient - together they prove the
isolation boundary was specifically defeated by the proxy layer, not
by a backend misconfiguration.

--- A REAL CONFIGURATION-MANAGEMENT MISTAKE, CAUGHT AND DOCUMENTED ---
A backup config file placed inside nginx's auto-included sites-enabled
directory caused nginx to load it as live config ("duplicate upstream"
error on nginx -t). Real, concrete lesson: NEVER store backup/inactive
config files inside a directory a service automatically scans and
loads from - keep backups fully outside any auto-include path.

--- REMEDIATION MUST BE VERIFIED FROM THE ATTACKER'S OWN VANTAGE POINT ---
After removing the vulnerable proxy route, the fix was re-tested from
centos9 (the same host used to prove the vulnerability existed) - not
just locally on the target. A fix that "looks right" in the config
file is not verified until re-tested from the same position the
original exploit was proven from.

--- CORE SECURITY LESSON ---
127.0.0.1 binding =/= complete application isolation. Any other
network-facing service on the same host that can proxy or forward
requests can defeat a loopback binding entirely. The real security
boundary must be evaluated across the WHOLE request path - who can
reach the frontend, what paths it exposes, where those paths route,
what the backend actually contains - not just at the backend's own
socket.

--- PRODUCTION RELEVANCE ---
This is a genuinely common, real-world misconfiguration class -
internal admin panels, debug endpoints, or management interfaces
bound to loopback "for safety," inadvertently exposed by a reverse
proxy, load balancer, or API gateway rule added later without
re-auditing the full request path. Any time a new proxy location or
forwarding rule is added, the question "does this expose something
that was relying on loopback-only binding for its security" should be
asked explicitly, not assumed answered by the backend's own config.
