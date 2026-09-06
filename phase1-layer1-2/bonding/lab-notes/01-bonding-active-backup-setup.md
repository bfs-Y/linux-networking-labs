# Lab Notes: NIC Bonding (active-backup)

## Objective
Combine two interfaces into one logical bond for redundancy - if one
NIC fails, traffic keeps flowing over the other with no interruption.

## Prerequisite
    lsmod | grep '^bonding'
Check the bonding kernel module is loaded before configuring anything.
If empty:
    sudo modprobe bonding

## Create the bond with the correct mode
    sudo ip link add bond0 type bond mode active-backup
Do not omit "mode" - the default is balance-rr (round-robin load
balancing), NOT failover. For pure redundancy, active-backup is the
correct mode: one slave active at a time, the other standing by.

## Enable real failure detection
    sudo ip link set bond0 type bond miimon 100
miimon defaults to 0 (disabled) - without setting a real polling
interval (in ms), the bond has no mechanism to actually detect a
failed link at all.

## Enslaving a member interface - critical order of operations
A member interface must have NO IP address assigned before it can be
enslaved. Attempting to enslave an interface that still has a live IP
fails SILENTLY (no error, but "Currently Active Slave: None" if you
check /proc/net/bonding/bond0 afterward).

For a NON-critical interface (no live traffic depending on it):
    sudo ip link set <if> down
    sudo ip link set <if> master bond0

For a CRITICAL interface (e.g. your active SSH/management path):
this requires moving the IP off the interface and onto the bond in
one atomic step, since there is a real window with no connectivity
between removing the IP and re-adding it on bond0. Chain the commands
to minimize the gap:
    sudo ip addr del <ip>/<prefix> dev <if> && \
    sudo ip link set <if> down && \
    sudo ip link set <if> master bond0 && \
    sudo ip link set bond0 up && \
    sudo ip addr add <ip>/<prefix> dev bond0
Real risk: if the connection drops mid-sequence, recovery requires
console access (not SSH) until the bond is fully configured.

## Post-migration cleanup - check for stale routes
After moving an IP from a physical interface to bond0, the routing
table often retains OLD routes still pointing at the physical
interface directly (duplicate subnet route, stale default route).
    ip route
Look for any route still referencing the old interface name instead
of bond0, and remove it:
    sudo ip route del <network> dev <old-if>
    sudo ip route del default dev <old-if>
    sudo ip route add default via <gateway> dev bond0

## Verify bonding state (authoritative source)
    cat /proc/net/bonding/bond0
This is the real, authoritative bond status - shows Currently Active
Slave, per-slave MII Status, Link Failure Count. Do NOT rely on
ip link show / ip -d link show alone to confirm a slave attached
successfully - they can look fine even when enslavement silently
failed. Always cross-check against /proc/net/bonding/bond0.

## Testing failover - watch for false negatives
Before testing, clear/verify ARP state for any critical peer (e.g.
the gateway) if the IP/interface configuration recently changed.
A stale ARP cache entry can produce a connectivity failure that looks
like a bonding failure but isn't - check /proc/net/bonding/bond0
directly during any failed test to see whether the bond itself
actually failed over, independent of what a ping result suggests.

Real test:
    sudo ip link set <active-slave-if> down
    cat /proc/net/bonding/bond0   # confirm Currently Active Slave changed
    ping -c 4 <target>            # confirm 0% loss throughout

Recovery:
    sudo ip link set <if> up
The bond driver polls on its miimon interval - MII Status may take up
to that interval to reflect the interface being back up; don't assume
failure from an immediate check.

## Lesson
Silent failures are the norm here, not the exception: enslaving an
interface with a live IP fails without an error message, and a
connectivity test can fail for reasons unrelated to bonding itself.
Always verify against /proc/net/bonding/bond0 directly rather than
inferring bond health from a ping result or from the absence of an
error message.
