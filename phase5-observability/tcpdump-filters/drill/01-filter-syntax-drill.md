TOPIC: tcpdump filter construction, DNS transaction IDs, background noise diagnosis
DATE STARTED: 2026-09-02
TARGET: answer all drills without checking reference

DRILL 1 - What tcpdump filter captures only DNS traffic?
YOUR ANSWER:
>
REFERENCE:
udp port 53 (DNS normally runs over UDP, confirmed in Phase 3's TCP
vs UDP lab-notes with a real packet-count comparison against HTTP).

DRILL 2 - What's the minimal tcpdump filter that captures ALL traffic
involving a specific IP, regardless of protocol or port?
YOUR ANSWER:
>
REFERENCE:
host <IP>

DRILL 3 - A capture filtered on `host 192.168.122.1` shows a packet
whose DESTINATION is a completely different address (e.g. a multicast
group). The filter didn't ask for that destination at all. Is this a
filter bug?
YOUR ANSWER:
>
REFERENCE:
No - `host <IP>` matches if that IP is EITHER the source or the
destination. If 192.168.122.1 was the SOURCE of that packet, it
correctly matches regardless of what the destination is.

DRILL 4 - Write a filter that captures traffic to/from 192.168.122.1
but excludes both ARP and DNS.
YOUR ANSWER:
>
REFERENCE:
host 192.168.122.1 and not arp and not port 53

DRILL 5 - Why does `host <IP>` match ARP packets, when ARP isn't
IP-routed traffic in the same sense as ICMP or TCP/UDP?
YOUR ANSWER:
>
REFERENCE:
ARP packets still carry IP addresses as payload data (e.g. "who-has
X tell Y"). tcpdump's host filter looks inside recognized protocol
fields for a matching address, not just the outer IP header.

DRILL 6 - Two DNS packets share the same transaction ID (e.g. 6576) -
one is the query, one is the response. What is this ID for, and why
does it matter on a resolver serving many simultaneous clients?
YOUR ANSWER:
>
REFERENCE:
It lets the resolver's response be matched back to the correct
original query. Without it, a busy resolver answering many clients at
once would have no way to know which response belongs to which
question.

DRILL 7 - For a forged/spoofed DNS response to be accepted by a
client, what THREE things does an attacker need to get right?
YOUR ANSWER:
>
REFERENCE:
The destination port (semi-random ephemeral port per query), the
transaction ID, and the exact question being asked - all before the
real response arrives.

DRILL 8 - Why is blind, off-network DNS spoofing hard, while an
attacker already on the local network has a much easier path?
YOUR ANSWER:
>
REFERENCE:
An off-network attacker has to blindly guess two effectively-random
numbers (port + transaction ID) and win a timing race against the
real response, without ever seeing the real query. An on-network
attacker (e.g. via ARP poisoning) can directly observe the real
query's port/ID/question and craft a perfect matching forged response.

SPEED ROUND - cover reference column, answer aloud:
Capture only DNS traffic -> udp port 53
Capture all traffic for one IP, any protocol -> host <IP>
Exclude a condition in a filter -> not <condition>
host filter matches which side of a packet -> either source or destination
DNS query/response matching mechanism -> transaction ID
Three things needed to forge a DNS response -> port, transaction ID, matching question

WEAK SPOT LOG:
Date | What I got wrong | Fixed?
2026-09-02 | Initially answered "DNS uses TCP" before checking own Phase 3 lab-notes, which already confirmed UDP with real evidence | Y
