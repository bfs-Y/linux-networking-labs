# Lab Notes: tcpdump Filter Syntax and DNS Transaction IDs
Topic: BPF filter construction, DNS query/response matching as a security mechanism

--- FILTER SYNTAX BUILDS FROM SIMPLE PIECES ---
Confirmed the pattern already used unknowingly in Phase 3
(`host $TARGET_IP and tcp port 80`) generalizes cleanly:
  Protocol + port:  udp port 53          (matches DNS - confirmed via
                                           Phase 3's own lab-notes,
                                           which already established
                                           DNS normally runs over UDP,
                                           not TCP)
  Single IP, any protocol/port:  host <IP>
  Boolean logic:  and, or, not - plain English keywords
  Combined:  host 192.168.122.1 and not arp and not port 53

--- host MATCHES EITHER SOURCE OR DESTINATION ---
Confirmed live: `host 192.168.122.1 and not arp and not port 53`
still captured a packet whose DESTINATION was 239.255.255.250 (SSDP/
UPnP multicast, port 1900) - because 192.168.122.1 was the SOURCE of
that packet. `host <IP>` matches on either side of a packet, not just
one direction. A filter written assuming "this only catches traffic
TO this IP" will silently also catch unrelated traffic FROM that IP -
verify which side actually matched before assuming a capture is
scoped the way you intended.

--- host ALSO MATCHES INSIDE NON-IP-ROUTED PROTOCOLS ---
ARP isn't IP-layer traffic in the routing sense, but ARP packets
still carry IP addresses as payload data (e.g. "who-has 192.168.122.226
tell 192.168.122.1"). Confirmed live: `host 192.168.122.1` matched ARP
request/reply packets even without any ARP-specific filter term,
because tcpdump looks inside recognized protocol fields for a matching
address, not just the outer IP header.

--- DNS TRANSACTION IDs: MECHANISM AND SECURITY RELEVANCE ---
Every DNS query/response pair shares a transaction ID (visible in
tcpdump output, e.g. "6576+ [1au] A? wikipedia.org." paired with
"6576 1/0/1 A 185.15.58.224"). This ID lets a resolver serving many
simultaneous clients match each response back to its correct request.
Reasoned through, not just observed: for a forged/spoofed DNS
response to be accepted, an attacker needs to correctly guess THREE
things simultaneously - the destination port (a semi-random ephemeral
port per query, e.g. 46625, not the well-known 53), the transaction
ID, and the exact question being asked - all before the real response
arrives. This is why blind, off-network DNS spoofing is genuinely
hard (guessing two effectively-random numbers and winning a race),
while an attacker who IS on the local network (can observe the real
query directly, e.g. via ARP poisoning) has a much easier path -
they see the real port/ID/question and can craft a perfect match.

--- BACKGROUND NETWORK NOISE IS REAL, NOT A FILTER BUG ---
A capture scoped to a specific host produced unexpected results
(SSDP multicast traffic) not because the filter was wrong, but
because that host was genuinely, independently generating that
traffic in the background (libvirt gateway announcing itself via
UPnP). Lesson: unexpected packets in a capture are worth
investigating as a real finding before assuming the filter is broken
- check what protocol/port is actually involved (in this case, a
quick lookup on port 1900 identified SSDP) rather than dismissing it.

--- PRODUCTION RELEVANCE ---
Writing a precise capture filter is itself a diagnostic skill - a
too-broad filter drowns you in unrelated noise (as seen here), a
too-narrow filter can silently miss the traffic you actually need
(e.g. filtering only by destination when the traffic you want is
outbound-sourced). Understanding what a filter actually matches
against (both directions, and inside non-obvious protocol payloads)
prevents both failure modes.
