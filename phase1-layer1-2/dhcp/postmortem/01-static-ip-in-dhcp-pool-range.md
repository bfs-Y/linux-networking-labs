# Postmortem
Date: 2026-07-27
Lab: Phase 1 — DHCP pool-range static IP conflict risk

## Symptom (verbatim command and output)
Command: sudo ip addr add 192.168.122.50/24 dev enp1s0
Second run: Error: ipv4: Address already assigned.

## Finding
Manually assigning a static IP inside a network's active DHCP pool range
(here, default network's 192.168.122.2-.254) creates a real risk: DHCP
may later hand that same address to a different host, causing an IP
conflict between the manually-configured machine and the DHCP client.

## Evidence
ip addr show enp1s0 confirmed the secondary address (192.168.122.50)
was successfully added alongside the DHCP-assigned primary (192.168.122.227).
The "Address already assigned" error on a repeat run confirmed the
address was genuinely held by the interface, not a phantom state.

## What changed vs what stayed the same
Changed: enp1s0 gained a secondary IP (192.168.122.50).
Stayed the same: primary DHCP-assigned address (192.168.122.227),
routing, ARP state.

## Fix applied
sudo ip addr del 192.168.122.50/24 dev enp1s0
Verified via ip addr show enp1s0 — secondary address removed, only the
original DHCP address remained.

## Automated or permanent version of the fix
N/A for this specific test — the real prevention is procedural: always
check `virsh net-dumpxml <network>` for the DHCP range BEFORE manually
assigning any static IP on that network, never assume a "safe-looking"
address is actually outside the pool.

## Detection gap
No automated check currently exists to warn if a manually-assigned IP
falls inside an active DHCP range. In a real environment, this would only
surface as an intermittent, hard-to-diagnose conflict when DHCP eventually
assigns the same address to another host — a good candidate for a future
harden/ script that cross-references a proposed static IP against
`virsh net-dumpxml`'s DHCP range before allowing the assignment.
