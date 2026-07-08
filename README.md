# linux-networking-labs

Protocol-deep networking labs — how packets actually move, and how to
troubleshoot connectivity. Companion repos:
- `linux-break-fix-harden` — general Linux administration
- `linux-security-labs` — attack/defense/detection content (ARP poisoning,
  firewall exploitation, TLS spoofing, and other adversarial scenarios that
  used to live here)

This repo is scoped to mechanism only — no adversary involved. If a script
assumes an attacker, it belongs in `linux-security-labs`, not here.

## Structure

Organized by learning phase, not flat topic folders:
## Phases

- `phase0-infra/` — KVM provisioning, cloud-init, topology, baseline capture (not yet built)
- `phase1-layer1-2/` — interfaces, ARP mechanism (not yet built), bridging/VLANs, container namespaces
- `phase2-layer3/` — IP addressing, routing, NAT, ICMP
- `phase3-transport/` — TCP/UDP connection states, load balancing
- `phase4-dns/` — DNS resolution (in progress)
- `phase5-observability/` — tcpdump/Wireshark, nmap, log analysis (not yet built)
- `phase6-capstone/` — multi-fault incidents, networking-focused CTF (not yet built)

See `BACKLOG.md` for what's tracked but not yet built.

## Environment

All labs run inside a KVM training VM (Ubuntu 24.04, `192.168.122.227`), not
the KVM host. Break/fix scripts assume this environment.
