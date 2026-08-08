TOPIC: Route metrics and selection
DATE STARTED: 2026-08-07
TARGET: answer all drills without checking reference

DRILL 1 - What does a route's "metric" number actually represent?
YOUR ANSWER:
>
REFERENCE:
How preferred that route is compared to others to the same destination - lower number means higher preference, it wins.

DRILL 2 - You add a route to a destination that already has a route, without specifying a metric on either. What actually happens - do you get a backup route?
YOUR ANSWER:
>
REFERENCE:
No - the second route silently REPLACES the first, since equal/unspecified metrics are ambiguous to the kernel. Only one route survives, confirmed absent from ip route show for the other.

DRILL 3 - You want two genuinely coexisting routes to the same destination - a real primary and backup. What must you do differently?
YOUR ANSWER:
>
REFERENCE:
Specify explicit, DISTINCT metrics on each route (e.g. metric 100 and metric 200) - only then does the kernel keep both instead of replacing one.

DRILL 4 - Two routes exist to the same destination with metric 100 and metric 200. Which one does the kernel actually use for real traffic, and how do you confirm it?
YOUR ANSWER:
>
REFERENCE:
The metric 100 route (lower wins). Confirm with ip route get <address-in-that-network> - shows which next-hop was actually selected.

DRILL 5 - ip route get shows a "uid 1000" field in its output. What does that represent?
YOUR ANSWER:
>
REFERENCE:
The user ID of the process that triggered the route lookup - informational metadata, not a routing decision factor in a basic setup (unless policy-based routing is configured).

SPEED ROUND - cover reference column, answer aloud:
Add a route with an explicit metric -> sudo ip route add <network> via <next-hop> metric <n>
Check all routes to a specific destination -> ip route show <network>/<prefix>
Check which route wins for a specific address -> ip route get <ip>
Remove a specific route (with metric, if ambiguous) -> sudo ip route del <network>/<prefix> via <next-hop> metric <n>

WEAK SPOT LOG:
Date | What I got wrong | Fixed?
2026-08-07 | Assumed adding a second route without a metric would create a backup - it silently replaced the original instead | Y
2026-08-07 | Guessed default metric would be 100 based on a half-remembered earlier observation, without verifying first | Y
