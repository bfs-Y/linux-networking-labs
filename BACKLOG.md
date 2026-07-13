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

## Phase 0 — autoinstall FULLY CONFIRMED (end to end)
training-vm-test successfully autoinstalled via virt-install + NoCloud seed,
survived a reboot, and SSH login succeeded with configured username/password.
Real debugging along the way: virtio-vga caused a black screen (switched to
--video qxl), --location failed on desktop ISO ("couldn't find kernel" —
desktop ISOs don't support --location extraction, only server ISOs do),
one manual "Install" click was needed due to Subiquity's default
confirmation pause (fix identified: interactive-sections: [] in YAML, not
yet re-tested). This proves the rebuild-training-vm.sh concept works.
Remaining: re-test with interactive-sections: [] for true zero-click.

## Phase 0 — interactive-sections: [] caused a stuck install (needs investigation)
Re-tested autoinstall with `interactive-sections: []` added to skip the
manual "Install" confirmation click. Result: install appeared to run
normally for ~10 minutes (high CPU activity, matching the first successful
run's pace), then activity dropped to near-idle with no SSH access and a
silent console — consistent with the installer stuck waiting on something,
possibly a step interactive-sections: [] skipped past without providing
the value it needed. Reverted to requiring one manual "Install" click
(known working, see prior entry) until this is properly investigated —
likely need `interactive-sections` to list only SPECIFIC sections to skip,
not blanket-empty, or need additional YAML fields the blanket skip assumed
were already answered.

## Phase 0 — hand-built network topology (training-lab) — DONE
Built a new libvirt network from scratch (training-lab, virbr2,
192.168.200.0/24, NAT forwarding, DHCP range .2-.254). Defined, started,
autostarted, verified bridge exists at OS level with correct addressing.
Confirmed UUID/MAC auto-generate on virsh net-define (don't need to be
specified). Validated via virt-install --dry-run that a guest could attach
to it. Full DHCP-lease-to-a-real-guest test not performed (time-bounded) but
XML/bridge-level verification is sufficient given identical structure to the
already-proven-working default network.
