# Recall Practice — Multi-Fault Capstone: Missing Route + Wrong Firewall Chain

TOPIC: Diagnosing Simultaneous, Independent Faults on a Routed Path
DATE STARTED: 2026-08-29
TARGET: answer without checking reference — write the actual command
        and reasoning, not just a guess.

DRILL 1 — A ping across a multi-hop path shows 100% loss. Before
touching any configuration, what's the first command to run, and
where (which machine in the path), to gather evidence without
guessing?
YOUR ANSWER:
>
REFERENCE:
Start a packet capture at the natural chokepoint (the intermediate
router) BEFORE reproducing the failure:
sudo ip netns exec <router> tcpdump -i any -n icmp &
then reproduce: sudo ip netns exec <client> ping -c 3 <destination>

DRILL 2 — A tcpdump capture at the router shows the echo-request
arriving and being correctly forwarded toward the destination, but
NO echo-reply ever appears in either direction. What does this narrow
the fault down to, and what would you check next?
YOUR ANSWER:
>
REFERENCE:
The outbound path is proven healthy; the fault is on/near the
destination, preventing the reply from ever being transmitted at all.
Next: check the destination's own routing table for a route back to
the source's subnet: ip route (run inside the destination namespace)

DRILL 3 — A destination host has no route back to the source's
subnet and no default route. What actually happens to its attempted
reply -- does it get sent to the wrong place, or does something else
happen?
YOUR ANSWER:
>
REFERENCE:
The packet is never transmitted at all. The kernel's route lookup for
the reply's destination fails outright with no usable route -- this
is silent, total loss, not misdirection.

DRILL 4 — You fix a routing issue and the ping now succeeds with 0%
loss. There was a SECOND fault injected that you haven't touched yet.
What's the discipline here -- do you declare the incident closed, or
what should you check regardless of the successful test?
YOUR ANSWER:
>
REFERENCE:
Never assume one fix closes a multi-symptom incident just because the
symptom you were chasing resolved. Explicitly check for any other
changes/rules still present (e.g. iptables -L on every relevant chain)
that may simply not have been triggered by this particular test.

DRILL 5 — A firewall rule blocking ICMP echo-reply is present on a
router's OUTPUT chain, syntactically correct, but shows 0 pkts/0 bytes
even after real matching traffic should have crossed the router. Why
did it never fire, and which chain should it actually be on?
YOUR ANSWER:
>
REFERENCE:
OUTPUT only matches traffic the router GENERATES itself. An
echo-reply from another host merely being relayed through the router
passes through the FORWARD chain instead -- a third, distinct chain
for traffic transiting the device without originating from or being
addressed to it.

DRILL 6 — Write the command to check whether an iptables rule has
actually matched any real traffic, not just whether it's present in
the chain listing.
YOUR ANSWER:
>
REFERENCE: iptables -L <chain> -v -n --line-numbers
(check the pkts/bytes columns for nonzero values)

SPEED ROUND — cover reference column, write the command aloud/on paper:

Capture at a chokepoint BEFORE reproducing a failure   -> tcpdump -i any -n icmp & (then trigger traffic)
Check a host's own routing table                        -> ip route
Check if a firewall rule has actually matched traffic   -> iptables -L <chain> -v -n --line-numbers
Add a missing route via a specific gateway              -> ip route add <subnet>/24 via <gateway>
Remove a specific, ineffective firewall rule            -> iptables -D <chain> <exact-rule-spec>
Distinguish traffic TO, FROM, and THROUGH a router      -> INPUT (to self) / OUTPUT (from self) / FORWARD (passing through)

WEAK SPOT LOG:
Date       | What I got wrong | Fixed?
