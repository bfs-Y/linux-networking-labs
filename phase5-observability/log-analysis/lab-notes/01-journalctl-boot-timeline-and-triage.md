# Lab Notes: journalctl Boot Timeline and Log Triage
Topic: Scoping kernel logs to a boot session, reconstructing a real timeline, triaging a logged block event

--- SCOPING LOGS TO THE CURRENT BOOT ---
`sudo journalctl -k -b` - `-k` filters to kernel messages only (same
source as [UFW BLOCK] entries used throughout this training), `-b`
scopes to the CURRENT boot session only, avoiding a mix of old and
new log entries across reboots. Grepping further for interface names
(enp1s0, enp7s0) or keywords (link, carrier) narrows to network-
relevant events specifically.

--- REAL BOOT TIMELINE, RECONSTRUCTED FROM TIMESTAMPS ---
Confirmed live, this machine's actual last boot:
  09:03:19 - kernel registers network protocol families (PF_NETLINK,
             PF_ROUTE) - earliest network subsystem init
  09:03:20 - interfaces get their real names: virtio0 -> enp1s0,
             virtio5 -> enp7s0 (this is the moment "enp1s0" as a name
             starts existing, before that it's just "eth0")
  09:04:26 - first [UFW BLOCK] entries appear, targeting WS-Discovery
             multicast traffic (see below)
Reading logs in raw chronological order and matching timestamps
across seemingly unrelated lines is the actual mechanic of building
an incident timeline - not a special tool, just careful reading of
what happened in what order.

--- TRIAGING A LOGGED BLOCK EVENT: WS-DISCOVERY ON PORT 3702 ---
Found: [UFW BLOCK] entries for UDP port 3702 to multicast address
239.255.255.250 (IPv4) and ff02::c (IPv6), sourced from this machine
itself. Researched port 3702 rather than assuming: it's WS-Discovery
(Web Services Dynamic Discovery), a Windows-originated multicast
protocol for devices (printers, scanners, network appliances) to
announce themselves and discover each other automatically - similar
purpose to SSDP (port 1900, already seen earlier this phase from
centos9's gateway) but a different protocol/port.
Triage question applied (same framework as Nmap exposure validation):
does this lab actually need WS-Discovery reachable - is there a
printer/scanner/discoverable device this machine needs to find or be
found by? No. Conclusion: this is expected, harmless background
noise, correctly blocked by UFW's default-deny policy - not a
security problem, not something to "fix." The firewall doing exactly
its intended job.

--- THE GENERAL TRIAGE PATTERN FOR ANY LOGGED "BLOCK" EVENT ---
1. Identify what's actually being blocked (source, destination, port,
   protocol) - don't skip past this to jump straight to a verdict.
2. If the port/protocol is unfamiliar, research it properly (what is
   it for, what legitimately uses it) rather than guessing or
   assuming malice.
3. Ask whether this specific machine/environment has any legitimate
   need for that traffic. If not, a block is correct, expected
   behavior - not an incident.
4. Only escalate to "real problem" if something the environment
   genuinely needs is the thing being blocked (the inverse case,
   already seen earlier this phase: a firewall correctly allowing
   something, but the service behind it wasn't running).

--- PRODUCTION RELEVANCE ---
Real incident response often means reading through large volumes of
routine, harmless log noise (multicast discovery protocols, broadcast
traffic, background chatter) to find or rule out genuine problems.
The skill isn't pattern-matching on scary-looking words like "BLOCK"
- it's correctly triaging each finding against what the environment
actually needs, the same discipline applied throughout this entire
training's break/fix work.
