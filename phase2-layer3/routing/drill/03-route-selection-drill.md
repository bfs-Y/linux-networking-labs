# Recall Practice — Route Selection: Longest Prefix Match

TOPIC: Longest Prefix Match / Route Specificity
DATE STARTED: 2026-08-20
TARGET: answer without checking reference — write the actual command.

DRILL 1 — Two routes exist for overlapping destinations: a /24 connected
route and a /32 host-specific route via a different gateway. Which one
does the kernel use for traffic to the address covered by the /32?
YOUR ANSWER:
>
REFERENCE:
The /32 route -- longest prefix match always wins, regardless of route
age, order, or which one was added first.

DRILL 2 — You want to prove, with real command output, which route the
kernel will actually use for a specific destination BEFORE sending any
traffic. Write the command.
YOUR ANSWER:
>
REFERENCE: ip route get <destination-ip>

DRILL 3 — You need to force traffic to one specific host through a
different gateway than the rest of its /24 subnet, without touching the
subnet's existing route. Write the command.
YOUR ANSWER:
>
REFERENCE: sudo ip route add <host-ip>/32 via <different-gateway-ip>

DRILL 4 — A host is unexpectedly routing through an unfamiliar gateway
even though its subnet's connected route looks correct. What single
command reveals every route in the table, so you can spot an unexpected
/32 entry?
YOUR ANSWER:
>
REFERENCE: ip route

DRILL 5 — You find and want to remove a specific injected /32 route.
Write the exact removal command (must match the route's via/dev exactly
or the kernel won't find it to delete).
YOUR ANSWER:
>
REFERENCE: sudo ip route del <host-ip>/32 via <gateway-ip>

SPEED ROUND — cover reference column, write the command aloud/on paper:

Check which route the kernel will actually use          -> ip route get <ip>
See the full routing table                                -> ip route
Add a host-specific route overriding the subnet route     -> ip route add <ip>/32 via <gw>
Remove a specific route                                    -> ip route del <ip>/32 via <gw>

WEAK SPOT LOG:
Date       | What I got wrong | Fixed?
