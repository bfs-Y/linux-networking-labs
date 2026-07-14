# Daily Drill — Phase 1: Interfaces & DHCP Diagnosis

TOPIC: Layer 1/2 Elimination Sequence and DHCP Design-vs-Fault Reasoning
DATE STARTED: 2026-07-13
TARGET: answer all drills without checking reference — write the
        actual command you would type, not a description of it.

DRILL 9 — Interface shows UP but no traffic passes, not even ARP
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

DRILL 10 — nmcli device status shows an interface permanently stuck
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

DRILL 11 — You've confirmed a libvirt network has no DHCP by design,
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
