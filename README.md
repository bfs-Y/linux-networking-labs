# linux-networking-labs

Protocol-deep networking labs — how packets actually move, and how to
troubleshoot connectivity, on real KVM-provisioned VMs with real packet
captures as evidence. Every finding is backed by command output, not
assumption.

Companion repos:
- `linux-break-fix-harden` — general Linux administration
- `linux-security-labs` — attack/defense/detection content (ARP poisoning,
  firewall exploitation, TLS spoofing, and other adversarial scenarios)

This repo is scoped to mechanism only — no adversary involved. If a lab
assumes an attacker, it belongs in `linux-security-labs`, not here.

## Structure

Organized by learning phase (roughly OSI-layer-aligned), each topic folder
following a consistent pattern: `break/ fix/ harden/ drill/ postmortem/`.

## Phases

- `phase0-infra/` — KVM provisioning, topology, automated baseline capture
  (working `capture-baseline.sh`: SSH-triggered VM-to-VM traffic, setcap-based
  unprivileged tcpdump, `set -e`-safe), PS1 operational hardening, recall drill
- `phase1-layer1-2/` — interfaces (Layer 1/2 diagnostic sequence, DHCP
  design-vs-fault postmortem), ARP resolution mechanism (real capture with
  microsecond-precision causal ordering), container namespaces
- `phase2-layer3/` — IP addressing, routing, NAT, ICMP (in progress)
- `phase3-transport/` — TCP/UDP connection states, load balancing (in progress)
- `phase4-dns/` — DNS resolution (in progress)
- `phase5-observability/` — tcpdump/Wireshark, nmap, log analysis (not yet built)
- `phase6-capstone/` — multi-fault incidents, networking-focused CTF (not yet built)

See `BACKLOG.md` for what's tracked but not yet built.

## Representative postmortems

- `phase1-layer1-2/arp/postmortem/` — ARP resolution mechanism, proven via
  packet timestamps that address resolution strictly precedes IP-layer
  transmission
- `phase1-layer1-2/interfaces/postmortem/` — distinguishing "network is
  broken" from "network was never designed to provide DHCP here," verified
  independently across two VMs

## Environment

KVM/libvirt hypervisor (Ubuntu) hosting two VMs:
- `training-vm` (Ubuntu 24.04, `192.168.122.227`) — primary lab VM
- `centos9` (CentOS 9, `192.168.122.207`) — secondary VM for cross-host
  scenarios

Two libvirt networks: `default` (NAT, DHCP-enabled, `virbr0`) and `isolated`
(no DHCP by design, `virbr1`). Break/fix scripts specify which host they run
on; several scenarios in this repo exist specifically because that
distinction was missed at least once during development.
