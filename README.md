# linux-networking-labs

Protocol-deep networking labs — TCP/IP, DNS, NAT, ARP, container networking, load balancing, TLS, and packet-level attack/defense scenarios. Companion repo to `linux-break-fix-harden`, which covers general Linux administration; this repo goes deep on networking mechanisms specifically.

Each topic is a self-contained module:
## Topics

- `arp/` — ARP poisoning, static bindings, arptables rate-limiting, ARP change monitoring
- `nat/` — NAT/MASQUERADE break, fix, and verification
- `tcp-udp/` — TCP handshake capture and diagnosis, TCP vs UDP behavior
- `rogue-port/` — detecting and killing unexpected listening services
- `container-namespace/` — container network namespace break/fix
- `loadbalancer/` — load balancer setup and verification
- `tls/` — fake certificate detection and inspection
- `cleartext-capture/` — cleartext traffic capture and attack chain recognition

## Environment

All labs run inside a KVM training VM (Ubuntu 24.04, `192.168.122.227`), not the KVM host. Break/fix scripts assume this environment.

## Notes

Known gaps, tracked deliberately, not hidden:
- `tcp-udp/break/02b-tcp-vs-udp.sh` has no corresponding fix script (conceptual break, not a real fault to remediate — under review).
