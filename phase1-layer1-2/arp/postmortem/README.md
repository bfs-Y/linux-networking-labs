# Postmortem

Date: 2026-07-10

Lab: Phase 1 -- ARP Resolution Capture and MITM Exposure Analysis

## Symptom (verbatim command and output)

Command:
sudo tcpdump -i enp1s0 -n -e "arp or icmp"

Observed output:
10:33:02.269132 Request who-has 192.168.122.207 tell 192.168.122.227
10:33:02.269708 Reply 192.168.122.207 is-at 52:54:00:06:81:f9
10:33:02.269733 192.168.122.227 > 192.168.122.207: ICMP echo request
10:33:02.270205 192.168.122.207 > 192.168.122.227: ICMP echo reply

## Finding (adapted from "Root cause")

When no neighbor entry exists for a local IPv4 destination, the Linux kernel must first perform ARP resolution to learn the destination MAC address before it can transmit the ICMP packet; because ARP provides no authentication, any host on the same Layer 2 segment can potentially influence IP-to-MAC mappings through forged ARP replies.

## Evidence

Timestamps prove strict ordering: the ARP Request fired at 10:33:02.269132, the ARP Reply arrived at 10:33:02.269708 (576 microseconds later), and the ICMP Echo Request did not fire until 10:33:02.269733 -- 25 microseconds after the ARP Reply, and 601 microseconds after the original request. This confirms address resolution completed before IP-layer communication began; the kernel held the ICMP packet until it had a Layer 2 destination to send it to.

The capture also demonstrated that ARP Requests are broadcast (destination ff:ff:ff:ff:ff:ff) because the sender does not yet know the target's MAC, while the Reply is unicast because the responder learned the requester's MAC directly from the Request frame -- no second broadcast round-trip is needed.

## What changed vs what stayed the same

Stayed the same:
- IP configuration
- MAC addresses
- Routing table
- Bridge (virbr0)
- Neighboring hosts
- Physical and virtual topology

Changed:
- Ubuntu's neighbor table gained a new IP-to-MAC mapping after the ARP Reply
- Understanding expanded from treating ARP as a connectivity mechanism to recognizing it as an unauthenticated attack surface

## Mitigation applied (adapted from "Fix applied")

No configuration fault required correction -- this exercise demonstrated normal protocol behavior. As an operational safeguard, traffic was captured from both the VM interface (enp1s0) and the bridge (virbr0) to establish the difference between host-level and bridge-level visibility, which directly informs what a compromised host on the same segment could and could not observe without further action.

## Automated or permanent version of the fix

ARP itself cannot be "fixed" -- it is unauthenticated by design. In a production environment carrying sensitive traffic, mitigate ARP spoofing rather than the protocol:
- Dynamic ARP Inspection (DAI)
- DHCP Snooping (required to support DAI)
- Static ARP entries where operationally appropriate
- Port security
- Network segmentation (VLANs)
- Monitoring for duplicate or unexpected ARP announcements (gratuitous ARP anomalies)

## Detection gap

Before this exercise, connectivity was verified with ping alone -- confirming *that* two hosts could reach each other but not *how* that reachability was established at Layer 2. Capturing traffic during neighbor resolution exposed the exact packet sequence and made the unauthenticated nature of ARP, and its MITM exposure, directly visible. Future Layer 2 validation should capture packets rather than rely on ping success alone.
