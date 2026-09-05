# Lab Notes: Nmap Scanning Basics - Privilege, Port States, Real Findings
Topic: Host discovery, port state interpretation, service verification

--- SAFETY / SCOPE PRINCIPLE, STATED UP FRONT ---
Nmap is ACTIVE scanning (sends real probes), unlike tcpdump/Wireshark
which are passive (observe existing traffic). Only scan hosts/networks
you own or have explicit permission to scan - this lab's targets
(ubuntulab, centos9, the libvirt gateway) are entirely self-owned.

--- UNPRIVILEGED SCANS SILENTLY USE A DIFFERENT, WEAKER PROBE SET ---
Real incident this session: `nmap 192.168.122.207` (no sudo) reported
"Host seems down," even though centos9 was confirmed reachable via
SSH and a direct ping (0% loss). Root cause, confirmed via Nmap's own
documentation: default host discovery normally combines FOUR probes
(ICMP echo, TCP SYN/443, TCP ACK/80, ICMP timestamp) - but an
UNPRIVILEGED user can only send TCP SYN probes to ports 80/443 (via a
connect() call), not real ICMP. Since centos9's firewall doesn't
expose anything on 80/443, those SYN probes got no response, and
Nmap concluded the host was down - despite ICMP genuinely working.
Fix: `sudo nmap ...` restored the full probe set including real ICMP
echo, and the host correctly showed as up.
Lesson: an Nmap result that contradicts other evidence (e.g. a
successful ping) is worth checking privilege level before trusting
the "host is down" conclusion.

--- PORT STATES: OPEN vs CLOSED vs FILTERED (TWO KINDS) ---
Confirmed live, same real scan:
  open     - something is listening, actively serving a connection
             (22/tcp ssh)
  closed   - the probe reached the host, but nothing is listening to
             accept it (9090/tcp, see below)
  filtered (no-response)     - firewall silently drops the probe, no
             reply of any kind (988 ports here)
  filtered (admin-prohibited) - firewall actively/explicitly rejects
             with an ICMP message saying so (10 ports here)
Direct parallel to earlier work: no-response is a silent drop (same
concept as an unreachable resolver timing out), admin-prohibited is
an active rejection (same concept as a TCP RST vs a timeout).

--- NMAP'S DEFAULT SERVICE NAME IS A GUESS, NOT A VERIFICATION ---
Port 9090 was labeled "zeus-admin" by default - an old, unrelated
historical port-database assignment, not what's actually configured
there (Cockpit, a real web management service, confirmed via
firewall-cmd listing `cockpit` as an allowed service). Running
`-sV` (version detection) correctly identified the REAL service on
port 22 (OpenSSH 9.9, protocol 2.0) by actually probing and reading
its banner - but could NOT identify port 9090 at all, because there
was nothing listening there to probe (see next finding). Lesson: a
default Nmap service name is a port-number lookup table guess;
`-sV` gives a real, evidence-based identification, but only for
ports something is actually listening on.

--- REAL FINDING: FIREWALL ALLOWS A SERVICE THAT ISN'T RUNNING ---
Port 9090 showed CLOSED, not filtered - meaning the firewall let the
probe through fine, but nothing answered on the other side. Confirmed
directly on centos9:
  $ sudo systemctl status cockpit.socket
    Loaded: loaded ... disabled
    Active: inactive (dead)
    Listen: [::]:9090 (Stream)
firewalld's `cockpit` service rule is correctly configured to allow
traffic to 9090 - but the actual cockpit.socket unit is disabled and
never started. Two independent layers (firewall rule, service state)
both need to be correct for a service to be reachable; this is the
inverse of the earlier loadbalancer finding (there: service ran,
firewall blocked it; here: firewall allows it, service never started).

--- PRODUCTION RELEVANCE ---
A scan result showing "closed" for a port you expect to be open is a
real, actionable finding - check whether the service is actually
running (systemctl status) before assuming a network/firewall
problem. Conversely, don't trust a scanner's guessed service name
over direct verification - a stale port-database entry can mislead an
inventory or exposure-validation exercise if taken at face value.
