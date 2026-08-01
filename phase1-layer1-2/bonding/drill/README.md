TOPIC: NIC bonding (active-backup) - setup, silent failures, and failover testing
DATE STARTED: 2026-07-30
TARGET: answer all drills without checking reference

DRILL 1 - Before configuring a bond, what's the first thing to check, and what command?
YOUR ANSWER:
>
REFERENCE:
Whether the bonding kernel module is loaded: lsmod | grep '^bonding' - if empty, sudo modprobe bonding.

DRILL 2 - You create a bond with sudo ip link add bond0 type bond, no mode specified. What mode do you actually get, and why is that wrong for pure failover redundancy?
YOUR ANSWER:
>
REFERENCE:
balance-rr (round-robin) - the default. It's a load-balancing mode, not failover. For pure redundancy you need mode active-backup specified explicitly.

DRILL 3 - active-backup mode is set, but ip -d link show bond0 shows miimon 0. What's missing, and why does it matter?
YOUR ANSWER:
>
REFERENCE:
Link failure detection is disabled - miimon defaults to 0. Without setting a real polling interval (e.g. sudo ip link set bond0 type bond miimon 100), the bond has no mechanism to detect a failed link at all.

DRILL 4 - You run sudo ip link set <if> master bond0 with no error returned, but the interface never becomes an active slave. What's the likely cause, and how do you confirm it?
YOUR ANSWER:
>
REFERENCE:
The interface still has an IP address assigned - enslavement fails silently in that case. Confirm current IP with ip addr show <if>, and confirm the real failure with cat /proc/net/bonding/bond0 (shows Currently Active Slave: None).

DRILL 5 - You need to enslave your CURRENT live SSH/management interface to a bond without permanently losing connectivity. What's the real risk, and how do you minimize it?
YOUR ANSWER:
>
REFERENCE:
Real risk: a genuine gap with no connectivity between removing the IP from the physical interface and re-adding it on the bond - if the session drops, recovery needs console access, not SSH. Minimize by chaining all the commands (addr del, link down, master, bond up, addr add) into one line with && so the gap is as short as possible.

DRILL 6 - After moving an IP from a physical interface to bond0, ip route still shows entries referencing the old interface directly. Is this dangerous right now, and what should you do?
YOUR ANSWER:
>
REFERENCE:
Not immediately dangerous if the bond0 route has a better (lower) metric and wins - but it's stale, fragile state. Clean it up: sudo ip route del <network> dev <old-if>, and replace any stale default route the same way, pointing the new one at bond0.

DRILL 7 - You bring down the active slave to test failover. Ping to the gateway fails 100%. Does this prove the bond failed?
YOUR ANSWER:
>
REFERENCE:
No - check cat /proc/net/bonding/bond0 directly first. A ping failure can be caused by something unrelated (e.g. a stale ARP cache entry for the gateway) even when the bond's own failover mechanism worked correctly. Never conclude bond failure from a ping result alone.

DRILL 8 - You bring a previously-down slave back up with ip link set <if> up. An immediate check of /proc/net/bonding/bond0 still shows MII Status: down for it. Is this a fault?
YOUR ANSWER:
>
REFERENCE:
No - the bond driver polls link state on its miimon interval (e.g. every 100ms), not instantaneously. Wait briefly and re-check before concluding anything is wrong.

SPEED ROUND - cover reference column, answer aloud:
Check if bonding module is loaded -> lsmod | grep '^bonding'
Load the bonding module -> sudo modprobe bonding
Create a bond in active-backup mode -> sudo ip link add bond0 type bond mode active-backup
Set link failure detection interval -> sudo ip link set bond0 type bond miimon 100
Enslave a clean (no-IP) interface -> sudo ip link set <if> down && sudo ip link set <if> master bond0
Check authoritative bond status -> cat /proc/net/bonding/bond0
Set a specific interface as primary slave -> sudo ip link set bond0 type bond primary <if>
Check which interfaces are enslaved to a bond -> ip link show master bond0

WEAK SPOT LOG:
Date | What I got wrong | Fixed?
2026-07-30 | Created bond0 without specifying mode, got balance-rr by default instead of active-backup | Y
2026-07-30 | Tried enslaving enp1s0 while it still had a live IP - failed silently, no error shown | Y
2026-07-30 | Misread a stale-ARP-caused ping failure as a bonding failure on first failover test | Y
2026-07-30 | Left stale routes referencing the old physical interface after moving the IP to bond0 | Y
