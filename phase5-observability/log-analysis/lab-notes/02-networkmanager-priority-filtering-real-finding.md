# Lab Notes: NetworkManager Log Filtering - A Real Finding
Topic: Unit-scoped logs, priority filtering, time-windowing, correctly triaging multiple findings

--- PERMISSIONS GATE ON journalctl: CHECK GROUPS, NOT JUST SUDO ---
`journalctl -u NetworkManager` (no sudo) returned "No entries" with a
hint: users need to be in `adm` or `systemd-journal` to see full
system logs. Confirmed via `groups` (training, sudo, wireshark - no
adm/systemd-journal). `sudo journalctl -u NetworkManager` correctly
showed full history. An empty journalctl result under a normal user
can mean "no access," not "nothing happened" - check group membership
before concluding a log source is silent.

--- UNIT-SCOPED LOGS ARE CLEANER THAN KERNEL-KEYWORD GREPPING ---
`sudo journalctl -u NetworkManager` isolates exactly one service's
own log stream - no ACPI/SATA/unrelated kernel noise mixed in (unlike
the earlier `journalctl -k -b | grep enp1s0` approach from the first
log-analysis session). Better tool for a service-specific
investigation.

--- --since / --until FOR TIME-WINDOWED INVESTIGATION ---
`sudo journalctl -u NetworkManager --since "<time>" --until "<time>"`
correctly narrowed output to a specific ~20-minute window around a
real event (a DHCP re-negotiation after a 9-hour gap), instead of
scrolling the full day's log. Confirmed live, worked exactly as
expected.

--- -p warning FOR PRIORITY FILTERING ---
`sudo journalctl -u NetworkManager -p warning` filtered out all
routine <info> noise (DHCP renewals, state changes), surfacing only
warning-level-or-higher entries. This is what actually found the two
real threads documented below - the info-level noise would have
buried both if read unfiltered.

--- REAL FINDING 1: A GENUINE, PREVIOUSLY-UNNOTICED SECURITY GAP ---
Recurring at nearly every single boot for over a year (file dated
Aug 5 2025): "Permissions for /etc/netplan/01-network-manager-all.yaml
are too open." Verified: file was -rw-r--r-- (644), readable by any
local user. Per Netplan's own official security documentation,
confirmed via web search against multiple independent sources
(official docs + a real bug report showing this EXACT warning on this
EXACT filename): netplan YAML files can contain credentials (VPN
keys, WiFi passwords) and should be chmod 600 (root read/write only).
Fixed: `sudo chmod 600 /etc/netplan/01-network-manager-all.yaml`.
Verified fix: `sudo netplan generate` now runs with zero warning
output, confirmed immediately, not just assumed. This is a genuine,
actionable finding this exercise surfaced that had never been noticed
before, despite recurring in the logs for over a year.

--- REAL FINDING 2 (CORRECTLY TRIAGED AS NOT AN INCIDENT): OPENVPN NOISE ---
Also recurring across many days: repeated `nm-openvpn` warnings/errors
- "secrets request canceled," "connect timeout exceeded," failed auth
reads - tied to two VPN profiles (vpnbook-us16-tcp443,
vpnbook-us178-tcp443). Confirmed with the operator (me): this is
known, intentional VPN usage - manually starting/stopping connections,
occasionally canceling a password prompt. Correctly triaged as
expected operational noise, NOT an incident, using the same framework
as the earlier WS-Discovery finding: is this something the operator
recognizes and expects? Yes -> not a problem, no action needed.

--- REAL FINDING 3 (CORRECTLY EXPLAINED, NOT AN INCIDENT): 9-HOUR GAP ---
A ~9 hour gap in DHCP lease renewals, followed by a full "no lease ->
new transaction" restart rather than a simple renewal, initially
looked like a possible fault. Correctly explained by the operator:
the VM was suspended (not shut down) for that window - a suspend/
resume cycle naturally produces exactly this log signature (existing
lease/session state not cleanly carried across the suspend, requiring
a fresh DHCP negotiation on resume). Confirmed via --since/--until
narrowing to the exact restart window for close inspection.

--- THE GENERAL METHODOLOGY, PROVEN ON REAL DATA ---
1. Scope to the relevant unit (`-u NetworkManager`), not a keyword
   grep across all kernel messages.
2. Filter by priority (`-p warning`) to surface only entries that
   might matter, cutting through routine info-level noise.
3. Use --since/--until to narrow to a specific window once a
   candidate event/gap is identified.
4. For EVERY finding, ask: is this something the environment/operator
   recognizes and expects? If yes, it's noise (WS-Discovery, VPN
   activity, suspend/resume gap). If no, or if unfamiliar, research it
   properly (web search, docs) before acting - which is exactly what
   surfaced the real, previously-unknown netplan permissions gap.

--- PRODUCTION RELEVANCE ---
Real incident response frequently involves multiple simultaneous
findings in one log review - some are genuine issues, some are
expected operational noise, some require asking the person who was
actually operating the system (as done here) rather than guessing.
Triaging each finding independently, rather than treating "the log
review" as a single verdict, is what separates real analysis from a
surface-level scan.
