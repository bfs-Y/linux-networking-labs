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
# Recall Practice — Phase 1: Interfaces & DHCP Diagnosis

TOPIC: Layer 1/2 Elimination Sequence and DHCP Design-vs-Fault Reasoning
DATE STARTED: 2026-07-13
TARGET: answer all drills without checking reference — write the
        actual command you would type, not a description of it.

DRILL 1 — Interface shows UP but no traffic passes, not even ARP
replies from directly attached peers. Name the three checks, in
order, that rule out Layer 1/2 before you move to Layer 3.
YOUR ANSWER:
>
REFERENCE:
1) ip link show <if> -- check UP flag (admin state)
2) same output -- check LOWER_UP flag (link/carrier state)
3) sudo ethtool <if> -- check "Link detected: yes" (independent
   confirmation, plus speed/duplex/driver health)
If all three pass, move to Layer 2 verification via
tcpdump -i <if> -n -e "arp or icmp" before assuming Layer 3.

DRILL 2 — nmcli device status shows an interface permanently stuck
in "connecting (getting IP configuration)", retrying every ~45
seconds, journalctl shows repeated "ip-config-unavailable / no
lease". Write the two commands, run where, that tell you whether
this is a fault or the network was designed without DHCP.
YOUR ANSWER:
>
REFERENCE:
virsh net-dumpxml <network>   (on the hypervisor)
  -> check for a <dhcp> block; none means no addresses were ever
     meant to be issued.
ps aux | grep dnsmasq   (on the hypervisor)
  -> confirm no dnsmasq process is bound to that network's config.

DRILL 3 — You've confirmed a libvirt network has no DHCP by design,
and a VM keeps retrying anyway. You want to stop the retries but
keep the connection profile for later (e.g. static IP work soon).
Write the exact command.
YOUR ANSWER:
>
REFERENCE:
nmcli connection modify "<connection-name>" connection.autoconnect no
(verify with: nmcli device status -- interface should show
"disconnected", not "connecting")

SPEED ROUND — cover reference column, write the command aloud/on paper:

Check interface admin + link state in one command  -> ip link show <if>
Independently confirm link health                  -> sudo ethtool <if>
Watch ARP/ICMP actually cross the wire              -> sudo tcpdump -i <if> -n -e "arp or icmp"
Check if a libvirt network has DHCP configured      -> virsh net-dumpxml <network>
Confirm a DHCP server process is actually running   -> ps aux | grep dnsmasq
Stop an interface from retrying DHCP, keep profile  -> nmcli connection modify "<name>" connection.autoconnect no
Check current state of all interfaces at a glance   -> nmcli device status
Watch NetworkManager's own activity log             -> sudo journalctl -u NetworkManager --since "10 min ago" --no-pager

WEAK SPOT LOG:
Date       | What I got wrong                                          | Fixed?
2026-07-13 | Assumed missing DHCP lease meant a fault before checking   | Yes -- learned to verify network design intent first
2026-07-13 | Wrote postmortem fix for centos9 without verifying it live | Yes -- always verify claimed fixes with real output
