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

## Phase 1 — Layer 1/2, DHCP mechanism gap
Confirmed: default network (virbr0) runs DHCP, isolated network (virbr1)
does not — explains why enp1s0 gets an IPv4 address automatically and
enp7s0 only gets IPv6 link-local. Need a lab demonstrating DHCP lease
process directly (not yet built).

## Phase 0 — unattended install (real requirement, not yet done)
Dry-run validated virt-install command exists (rebuild-training-vm.sh), but
it boots to an INTERACTIVE installer, not unattended — does not meet Phase 0's
actual bar ("rebuild in under 10 minutes from a script, no hands").
Next step: write a minimal Ubuntu 24.04 autoinstall.yaml (Subiquity format),
build a NoCloud seed (user-data + meta-data), point virt-install at both ISO
and seed via --cloud-init or a second attached seed ISO. Test end-to-end.
This is a real, focused task — do it fresh, not at the end of a long session.

## Phase 0 — autoinstall confirmed working, one setting needed for full unattended
Autoinstall YAML correctly pre-configured locale/keyboard/identity/storage —
confirmed by reaching Subiquity's "review your choices" screen with all
fields pre-filled. Installer paused there waiting for manual "Install" click
(Subiquity default safety behavior). Fix for true zero-touch: add
`interactive-sections: []` to autoinstall.yaml. Not yet re-tested with that
setting added.

## Phase 0 — autoinstall CONFIRMED working (partial automation achieved)
Successfully autoinstalled Ubuntu 24.04 via virt-install + NoCloud seed ISO.
Locale, keyboard, identity, storage, SSH all correctly pre-configured from
YAML with zero manual input up to Subiquity's final confirmation screen.
One manual click ("Install") was required due to Subiquity's default safety
pause. Fix identified and applied to user-data for next run:
`interactive-sections: []`. Next test: confirm fully unattended (zero clicks)
completion with updated YAML.
