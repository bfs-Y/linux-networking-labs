TOPIC: ethtool/NIC diagnosis - virtual NIC limitations, throughput vs connectivity, service-side firewall
DATE STARTED: 2026-07-23
TARGET: answer all drills without checking reference

DRILL 1 - Link shows UP/LOWER_UP with zero errors on a VM's interface. User reports throughput is bad. What tool checks negotiated speed/duplex, and why might it report "Unknown" on a KVM guest?
YOUR ANSWER:
>
REFERENCE:
ethtool <if> - reports Unknown/Not reported on a virtio (or similar) virtual NIC because there's no real PHY chip for the driver to query; speed/duplex diagnosis doesn't apply to virtual interfaces.

DRILL 2 - Client gets "No route to host" connecting to a service on a known-good, reachable server. Route and ARP both check out clean on the client. What's the next thing to check, and on which host?
YOUR ANSWER:
>
REFERENCE:
Check the firewall on the SERVER (destination), not the client - "No route to host" from a rejected connection often originates from the destination's firewall rejecting the port, not a client-side routing failure.

DRILL 3 - A reported symptom is "throughput is terrible." Before trusting that description and diagnosing Layer 1/2, what's the first thing you should establish?
YOUR ANSWER:
>
REFERENCE:
Get a real, measured baseline (e.g. iperf3) before assuming the symptom is real or which layer it lives in - a hard connection failure and degraded throughput are different problems requiring different diagnostic paths, and "slow" is often actually "failed" until measured.

DRILL 4 - You need to confirm a service is actually listening on a given port on a remote host, independent of firewall state. What command, and what does it prove that firewall-cmd/ufw output doesn't?
YOUR ANSWER:
>
REFERENCE:
ss -tlnp | grep <port> - confirms the application itself is bound and listening. Firewall tools only show what's permitted to reach the host; they don't confirm anything is actually there to receive it.

DRILL 5 - You're about to remove a firewall rule to simulate a fault. What's the difference between a surgical fix (remove one port) and a destructive one (reset the whole zone), and why does it matter in production?
YOUR ANSWER:
>
REFERENCE:
Surgical: firewall-cmd --permanent --remove-port=<port>/tcp - touches only the target rule. Destructive: wiping/resetting the zone risks removing unrelated rules (e.g. SSH access), which in production could lock you out of the host entirely.

DRILL 6 - Two machines both have clones of the same Git repo. You push commits from one, then switch to the other and try to save a new file into a directory that "should" exist. It doesn't. What's the first command to run before assuming anything is broken?
YOUR ANSWER:
>
REFERENCE:
git pull - the second machine's local clone is stale and never fetched the other machine's pushed commits; always sync before assuming a missing file/directory means real corruption.

SPEED ROUND - cover reference column, answer aloud:
Check negotiated speed/duplex on an interface -> ethtool <if>
Confirm kernel's routing decision to a destination -> ip route get <ip>
Confirm Layer 2 resolution to a destination -> ip neigh show <ip>
Check active firewalld rules on a CentOS host -> sudo firewall-cmd --list-all
Check active ufw rules on an Ubuntu host -> sudo ufw status verbose
Confirm a service is listening on a given port -> ss -tlnp | grep <port>
Open one port permanently without touching other rules (firewalld) -> sudo firewall-cmd --permanent --add-port=<port>/tcp && sudo firewall-cmd --reload
Measure real throughput between two hosts -> iperf3 -s (server) / iperf3 -c <ip> (client)

WEAK SPOT LOG:
Date | What I got wrong | Fixed?
2026-07-23 | Assumed ethtool speed/duplex fields would explain a virtual NIC's throughput | Y
2026-07-23 | Diagnosed the wrong direction of firewall (client outbound) before checking the destination server | Y
2026-07-23 | Trusted "throughput terrible" as fact without ever measuring it | Y
2026-07-23 | Concluded fix worked from command ordering instead of a clean re-test | Y
2026-07-23 | Assumed repo state matched across two machines without pulling first | Y
