# Recall Practice — Phase 1: Linux Bridge, veth, Namespaces

TOPIC: Bridge Creation, veth Pairs, and Namespace Isolation
DATE STARTED: 2026-07-20
TARGET: answer all drills without checking reference — write the
        actual command you would type, not a description of it.

DRILL 1 — Create a new Linux bridge device named br0, then bring it
administratively up. Write both commands.
YOUR ANSWER:
>
REFERENCE:
sudo ip link add br0 type bridge
sudo ip link set br0 up

DRILL 2 — Create a veth pair named veth-host and veth-ns. Write the
command.
YOUR ANSWER:
>
REFERENCE:
sudo ip link add veth-host type veth peer name veth-ns

DRILL 3 — You want one end of a veth pair to join a bridge as a
member. Write the command to attach veth-host to br0, then bring it
up.
YOUR ANSWER:
>
REFERENCE:
sudo ip link set veth-host master br0
sudo ip link set veth-host up

DRILL 4 — You attached BOTH ends of the same veth pair to the same
bridge. What networking fault does this create, and in one sentence,
why?
YOUR ANSWER:
>
REFERENCE:
A Layer 2 loop / broadcast storm. A veth pair is a virtual cable;
plugging both ends into the same switch means a frame entering one
end exits the other and re-enters the bridge endlessly.

DRILL 5 — Correct architecture: one veth end goes on the bridge,
the other end must go somewhere ELSE. Write the three commands to
create an isolated namespace, move the other veth end into it, and
rename it to eth0.
YOUR ANSWER:
>
REFERENCE:
sudo ip netns add lab1
sudo ip link set veth-ns netns lab1
sudo ip netns exec lab1 ip link set veth-ns name eth0

DRILL 6 — A freshly created network namespace always starts with
its loopback interface down. Write the command to bring it up, plus
the command to bring the moved veth end up and assign it an IP.
YOUR ANSWER:
>
REFERENCE:
sudo ip netns exec lab1 ip link set lo up
sudo ip netns exec lab1 ip link set eth0 up
sudo ip netns exec lab1 ip addr add 10.10.10.2/24 dev eth0

DRILL 7 — You want to confirm which MAC addresses the bridge has
actually learned, and which port each lives behind. Write the
command.
YOUR ANSWER:
>
REFERENCE: bridge fdb show

DRILL 8 — From inside a namespace, you want to confirm ARP
resolution actually happened against the bridge's own MAC. Write
the command, run where.
YOUR ANSWER:
>
REFERENCE: sudo ip netns exec lab1 ip neigh   (run from the host,
targeting the namespace via ip netns exec)

SPEED ROUND — cover reference column, write the command aloud/on paper:

Create a bridge, bring it up                        -> ip link add br0 type bridge / ip link set br0 up
Create a veth pair                                   -> ip link add <a> type veth peer name <b>
Attach an interface to a bridge as a member          -> ip link set <if> master <bridge>
Create an isolated network namespace                 -> ip netns add <name>
Move an interface into a namespace                   -> ip link set <if> netns <namespace>
Run a command inside a namespace                     -> ip netns exec <namespace> <command>
Check the bridge's learned MAC-to-port table          -> bridge fdb show
Check forwarding state of a bridge port              -> bridge link
Check VLAN tagging state per port                     -> bridge vlan show

WEAK SPOT LOG:
Date       | What I got wrong                                          | Fixed?
2026-07-14 | Attached both ends of a veth pair to the same bridge --    | Yes -- rebuilt
           | created a Layer 2 loop instead of connecting two separate  | with correct
           | network contexts.                                         | namespace pattern
