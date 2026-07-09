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

## Phase 0 — Disk allocation exceeds capacity (snapshot chain buildup)
training-vm has a linear snapshot chain (snap1 -> clean-baseline-20260418 ->
pre-lab-module4-20260603 -> pre-lab-module5-20260604, current). Allocation
(55GB) exceeds Capacity (30GB) as a result. Decide which snapshots are still
needed as rollback points before pruning; understand virsh snapshot-delete /
blockcommit before acting.

## Phase 0 — remaining work (not done)
- Test rebuild-training-vm.sh against a throwaway VM, confirm it actually works
- Capture and commit a baseline: ip a, ip route, ip neigh, ss -tulpn, iptables -L -v, a clean tcpdump sample
- Understand what the "isolated" network (virbr1) was originally for
- Decide on snapshot chain pruning (see prior entry)
