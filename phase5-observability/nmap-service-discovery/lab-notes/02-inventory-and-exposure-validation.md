# Lab Notes: Inventory and Exposure Validation
Topic: Subnet-wide host discovery, config-vs-reality exposure checking

--- INVENTORY: -sn FOR HOST DISCOVERY ONLY, NO PORT SCAN ---
`sudo nmap -sn 192.168.122.0/24` swept the full /24 (256 addresses)
in ~2 seconds, correctly found exactly 3 live hosts: the gateway/
hypervisor (192.168.122.1, resolved to the actual physical laptop's
hostname), centos9 (.207), and ubuntulab itself (.226, no MAC shown
since it's the scanning host, not reached over the wire). Confirms
the documented lab topology matches live reality, with scan evidence
rather than just trusting README/topology docs.

--- EXPOSURE VALIDATION: CONFIG SAYS ALLOWED != CURRENTLY EXPOSED ---
Ran a full all-ports scan (`sudo nmap -p- <ip>`, ~150s for 65535
ports) against centos9. Real result:
  22/tcp   open   ssh
  5201/tcp closed targus-getdata1   (iperf3's real port)
  9090/tcp closed zeus-admin        (cockpit's real port)
Both 5201 and 9090 are explicitly allowed by firewalld's rules
(confirmed earlier this phase via firewall-cmd --list-all), but both
show CLOSED because nothing is currently listening on them - iperf3
only listens when manually started for a test, cockpit.socket is
disabled. This is the actual point of exposure validation: a
firewall's allow-list describes what COULD become reachable, not what
IS reachable right now. The real, current attack surface on centos9
at scan time was exactly one service: 22/tcp ssh - genuinely
open and answering, everything else merely permitted-but-dormant.

--- SCAN INTERPRETATION IS THE THREAD THROUGH BOTH ---
Every result in both scans required interpretation, not just reading
labels at face value:
  - "Host is up" with no MAC = the scanning host itself, not a
    remote host reached over the network
  - "closed" != "filtered" - closed means the probe reached the host
    and got an explicit non-listening response; filtered means the
    firewall blocked the probe before it got that far
  - A default service-name label (e.g. "targus-getdata1" for 5201,
    "zeus-admin" for 9090) is a stale port-database guess, not a
    verified identification - matched against real prior knowledge
    (5201 = iperf3, 9090 = cockpit) rather than trusted blindly
  - "Not shown: X filtered (no-response), Y filtered
    (admin-prohibited)" on a full 65535-port scan describes 65,532
    ports with two different firewall behaviors - most silently
    dropped, a smaller set actively rejected - real detail that a
    default ~1000-port scan's shorter "not shown" summary compresses
    away

--- PRODUCTION RELEVANCE ---
Inventory answers "what's actually out there." Exposure validation
answers "of what's out there, what's genuinely reachable right now,"
which a firewall config or service documentation alone cannot answer -
only a live scan (or equivalent direct verification) can. Treat a
scan's default service-name guesses as a starting hint, not a
conclusion - verify against what you actually know is supposed to be
running, or use -sV plus direct host verification (systemctl status,
firewall-cmd) to confirm.
