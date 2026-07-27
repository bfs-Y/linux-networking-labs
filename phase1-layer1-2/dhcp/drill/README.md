# Recall Practice — DHCP / Static IP Conflict Risk

TOPIC: DHCP Pool Range Awareness
DATE STARTED: 2026-07-27
TARGET: answer without checking reference — write the actual command.

DRILL 01 — You need to manually assign a static IP to a VM's interface.
Before doing so, what must you check to avoid a future address conflict?
YOUR ANSWER:
>
REFERENCE:
Check the DHCP pool range for that network — `virsh net-dumpxml <network>`
on the hypervisor shows the `<dhcp><range>` block. Pick a static IP OUTSIDE
that range.

DRILL 02 — Write the command to manually add a static IP to an interface,
and the command to remove it.
YOUR ANSWER:
>
REFERENCE:
sudo ip addr add <ip>/<prefix> dev <interface>
sudo ip addr del <ip>/<prefix> dev <interface>

DRILL 03 — Where does libvirt's dnsmasq record actual DHCP leases handed
out (not the traditional dnsmasq.leases file)?
YOUR ANSWER:
>
REFERENCE:
/var/lib/libvirt/dnsmasq/<bridge-name>.status — JSON format, written by
libvirt's leasehelper script, not dnsmasq's native lease file mechanism.

SPEED ROUND:
Check a network's DHCP range           -> virsh net-dumpxml <network>
Manually assign a static IP             -> ip addr add <ip>/<prefix> dev <if>
Remove a manually assigned static IP    -> ip addr del <ip>/<prefix> dev <if>
See real DHCP lease records             -> cat /var/lib/libvirt/dnsmasq/<bridge>.status

WEAK SPOT LOG:
Date       | What I got wrong | Fixed?

DRILL 04 — A DHCP lease has a Lease-Time of 3600 seconds. At roughly what
percentage of the lease time does the client first attempt renewal (T1),
and at what percentage does it attempt rebinding (T2) if renewal fails?
YOUR ANSWER:
>
REFERENCE:
T1 (renewal) at 50% of lease time, T2 (rebinding) at 87.5%. Confirmed live
via capture: Lease-Time=3600s, RN(T1)=1800s (exactly 50%), RB(T2)=3150s
(exactly 87.5%).
