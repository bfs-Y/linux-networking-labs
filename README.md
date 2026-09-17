# linux-networking-labs

Protocol-deep networking labs -- how packets actually move, and how to
troubleshoot connectivity, on real KVM-provisioned VMs with real packet
captures as evidence. Every finding is backed by command output, not
assumption.

Companion repos:
- [`linux-fundamentals-labs`](https://github.com/bfs-Y/linux-fundamentals-labs) -- general Linux administration
- [`linux-security-labs`](https://github.com/bfs-Y/linux-security-labs) -- attack/defense/detection content (ARP poisoning,
  firewall exploitation, TLS spoofing, and other adversarial scenarios)

This repo is scoped to mechanism only -- no adversary involved (except
Phase 6's CTF-style exercise, which is explicitly, self-contained
offense/defense practice against a target this repo also owns). If a
lab assumes an external attacker or adversarial scenario outside that
one exercise, it belongs in [`linux-security-labs`](https://github.com/bfs-Y/linux-security-labs), not here.

## Structure

Organized by learning phase, each topic folder following a core pattern:
`break/ fix/ drill/ lab-notes/ postmortem/`. A `testlog/` folder is added
where a topic needs a direct outcome check distinct from the fix itself.
Phase 6 capstones use only `lab-notes/postmortem/drill/` -- these are
live, cold-diagnosis exercises rather than reusable break scripts.

Folder names include an explicit OSI layer number through Phase 3, where
each phase maps cleanly to one layer. Phase 4 onward drop the layer
number deliberately: DNS is application-layer but commonly taught as its
own topic, and Observability/Capstones are intentionally cross-layer by
design -- forcing a single layer number onto them would misrepresent what
they cover.

Defensive/hardening content that assumes an adversary lives in the
companion repo, [`linux-security-labs`](https://github.com/bfs-Y/linux-security-labs), not here -- see the scope note
above. (Note: `phase0-infra/hardening/ps1-hardening.md` is PS1 prompt
cosmetics, not adversarial/security content, despite the folder name --
it correctly stays here, not in the companion repo.)

## Phases

All six phases are complete.

- `phase0-infra/` -- KVM provisioning, topology, automated baseline capture
  (`capture-baseline.sh`: SSH-triggered VM-to-VM traffic, setcap-based
  unprivileged tcpdump, `set -e`-safe), PS1 operational hardening (the
  incident that started it: `postmortem/01-wrong-host-ping-hypervisor-vs-vm.md`)
- `phase1-layer1-2/` -- interfaces/DHCP, ARP resolution (real capture with
  microsecond-precision causal ordering), bonding (active-backup failover),
  bridging (a real Layer 2 loop incident plus veth/namespace teardown
  behavior), container namespaces, ethtool/throughput diagnosis,
  MTU mismatch, `/sys/class/net` kernel counters, VLAN tagging
- `phase2-layer3/` -- IP addressing/CIDR, static routing and metrics,
  ICMP path diagnostics (found a real internet routing loop), NAT,
  firewall rule precedence, and an early multi-fault routing +
  firewall troubleshooting exercise
- `phase3-layer4-transport/` -- TCP/UDP connection states (handshake,
  TIME_WAIT/CLOSE_WAIT, backlog), load balancing (a real bind-and-firewall
  defect pair)
- `phase4-dns/` -- resolver chain, `/etc/hosts` override and backup
  integrity, `nsswitch.conf` ordering, dead-resolver cost, `dig +trace`
  recursive-vs-authoritative delegation
- `phase5-observability/` -- tcpdump/Wireshark (captures, capture vs
  display filters, packet analysis), Nmap (inventory, exposure
  validation -- a real firewall-allows-but-nothing-listening finding),
  log analysis (a real, previously-unknown security misconfiguration
  found and fixed via `journalctl` priority filtering)
- `phase6-capstone/` -- a blind, cold multi-fault incident (DHCP/ACD
  plus a genuinely obscure `strace`-uncovered backend bug) and a full
  HTB/CTF-style reverse-proxy exposure exercise (recon through
  remediation, verified from the attacker's own vantage point)

See `BACKLOG-ARCHIVE.md` for historical planning/debugging notes from
earlier in this repo's development - archived, not an active list.

## Representative postmortems

- `phase1-layer1-2/arp/postmortem/` -- three postmortems: ARP resolution
  proven via microsecond packet timestamps, a PERMANENT-entry fault, and
  gratuitous ARP behavior across entry states
- `phase1-layer1-2/dhcp/postmortem/` -- distinguishing "network is broken"
  from "network was never designed to provide DHCP here," plus a real
  ACD (Address Conflict Detection) lease-refusal incident -- later
  confirmed in Phase 6 as a still-unresolved RECURRING issue on the same
  host, not a one-off
- `phase4-dns/dns/postmortem/` -- a stale manual `/etc/hosts` poison
  contaminating an automated backup, and `getent hosts` silently
  diverging from real file content on this system
- `phase5-observability/log-analysis/postmortem/` -- a genuine, previously
  unnoticed netplan file-permissions security gap, found via
  `journalctl -u NetworkManager -p warning` and fixed live
- `phase6-capstone/multi-fault-networking-incident/postmortem/` -- blind
  diagnosis of two independent faults; a `write(2)` EIO traced via
  `strace` to a backend process's stderr pointing at a deleted
  pseudo-terminal

## Environment

KVM/libvirt hypervisor (Ubuntu) hosting two VMs:
- `ubuntulab` (Ubuntu 24.04, `192.168.122.226`) -- primary lab VM
- `centos9` (CentOS 9, `192.168.122.207`) -- secondary VM for cross-host
  scenarios

Two libvirt networks: `default` (NAT, DHCP-enabled, `virbr0`) and `isolated`
(no DHCP by design, `virbr1`). Break/fix scripts specify which host they run
on; several scenarios in this repo exist specifically because that
distinction was missed at least once during development.
