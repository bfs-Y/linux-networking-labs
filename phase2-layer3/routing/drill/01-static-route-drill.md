TOPIC: Static routing - why gateways don't automatically know new subnets
DATE STARTED: 2026-08-06
TARGET: answer all drills without checking reference

DRILL 1 - Host A creates a new subnet on one of its interfaces. Does the network's gateway automatically learn about it?
YOUR ANSWER:
>
REFERENCE:
No - a router/gateway only knows about networks it's been explicitly told about, via static config or a routing protocol. Creating a subnet on one host doesn't propagate that knowledge anywhere else automatically.

DRILL 2 - Host B pings an address in a subnet it has no route to. The result is 100% loss with NO "Destination Host Unreachable" message. What does this silence tell you, versus an ARP-failure message?
YOUR ANSWER:
>
REFERENCE:
Silent loss means the packet was routed somewhere (e.g. via the default gateway) and simply got no reply - a routing-layer outcome. An explicit "unreachable" message means an ARP resolution failure on a directly-reachable address - a different, earlier layer.

DRILL 3 - Write the command to add a static route to 10.50.0.0/28, delivered via a specific device at 192.168.122.226.
YOUR ANSWER:
>
REFERENCE:
sudo ip route add 10.50.0.0/28 via 192.168.122.226

DRILL 4 - In that route command, why is the destination written as 10.50.0.0 (ending in .0) rather than a specific host address like 10.50.0.5?
YOUR ANSWER:
>
REFERENCE:
The destination in a route always represents the WHOLE network block, using its network address - not one device. The "via" address is the specific device that handles delivery once traffic arrives.

DRILL 5 - You add a static route to a subnet on ONE host (e.g. centos9). Does this fix reachability for every other machine on the network too?
YOUR ANSWER:
>
REFERENCE:
No - a static route added on one host only fixes reachability FROM that host. Every other machine still fails the same way until they also get the route, or the actual gateway learns it.

DRILL 6 - You want to verify a specific route actually exists before testing connectivity. What command shows it?
YOUR ANSWER:
>
REFERENCE:
ip route show <network>/<prefix>

SPEED ROUND - cover reference column, answer aloud:
Add a static route via a specific next-hop -> sudo ip route add <network>/<prefix> via <next-hop-ip>
Check if a specific route exists -> ip route show <network>/<prefix>
Check which route the kernel will actually use for an address -> ip route get <ip>
Remove a route -> sudo ip route del <network>/<prefix>

WEAK SPOT LOG:
Date | What I got wrong | Fixed?
2026-08-06 | Initially unclear on gateway vs router terminology - required a full analogy rebuild (gate + person with a map) | Y
2026-08-06 | Confused which address in a route command represents the network vs the delivery device | Y
