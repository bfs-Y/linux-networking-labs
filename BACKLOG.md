# Topics not yet covered — add after DNS is complete
- Routing (static routes, multiple interfaces, gateway failure)
- DHCP (lease process, relay, rogue DHCP detection)
- ICMP (MTU discovery, traceroute mechanics)
- Bridges/VLANs (tagging, trunk vs access)
- Bonding (active-backup, 802.3ad failover)
- nftables (deep — NAT rules, port forwarding, conntrack)
- VPN (WireGuard or OpenVPN, tunnel troubleshooting)
- Latency/throughput (iperf3, path analysis)

## ARP mechanism content (not yet written)
phase1-layer1-2/arp/ is currently empty. Need: normal resolution walkthrough,
stale cache entry scenario, cache table exhaustion — no adversary, pure mechanism.
Baseline `ip neigh` capture also needed.

## Phase 5/6 (not yet started)
Observability/Analysis and Networking Capstones — reached later in curriculum.

## Phase 0 — VM has an unused isolated network (virbr1)
Training VM has a second NIC on an "isolated" libvirt network (no IP/DHCP
configured) — purpose unknown, not currently used. Investigate when Phase 0
is actually reached: what was it for, is it worth configuring, or should it
be removed from the VM definition.
