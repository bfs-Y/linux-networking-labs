# Postmortem
Date: 2026-07-10
Lab: Phase 1 -- ARP MITM Exposure Analysis
Companion to: linux-networking-labs/phase1-layer1-2/arp/postmortem/README.md
(same capture, mechanism-only version)

## Finding
ARP provides no authentication -- any host on the same Layer 2 segment can
potentially influence IP-to-MAC mappings through forged ARP replies.

## Why this matters
Understanding expanded from treating ARP as a connectivity mechanism to
recognizing it as an unauthenticated attack surface. Traffic was captured
from both the VM interface (enp1s0) and the bridge (virbr0) to establish
the difference between host-level and bridge-level visibility -- this
directly informs what a compromised host on the same segment could and
could not observe without further action.

## Mitigation (ARP itself cannot be "fixed" -- unauthenticated by design)
- Dynamic ARP Inspection (DAI)
- DHCP Snooping (required to support DAI)
- Static ARP entries where operationally appropriate
- Port security
- Network segmentation (VLANs)
- Monitoring for duplicate/unexpected ARP announcements (gratuitous ARP anomalies)
