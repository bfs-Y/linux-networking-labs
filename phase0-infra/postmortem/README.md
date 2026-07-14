Date: 2026-07-09
Lab: phase0/phase1 -- VM-to-VM connectivity check, training-vm (Ubuntu 24.04) <-> centos9 on virbr0

Symptom (verbatim command and output -- what I saw):
ping -c 4 192.168.122.207
PING 192.168.122.207 (192.168.122.207) 56(84) bytes of data.
64 bytes from 192.168.122.207: icmp_seq=1 ttl=64 time=0.857 ms
64 bytes from 192.168.122.207: icmp_seq=2 ttl=64 time=0.618 ms
64 bytes from 192.168.122.207: icmp_seq=3 ttl=64 time=0.548 ms
64 bytes from 192.168.122.207: icmp_seq=4 ttl=64 time=0.539 ms
--- 192.168.122.207 ping statistics ---
4 packets transmitted, 4 received, 0% packet loss

Paired tcpdump -i virbr0 (unexpected):
15:29:16.613684 IP 192.168.122.1 > 192.168.122.207: ICMP echo request, seq 1
15:29:16.614474 IP 192.168.122.207 > 192.168.122.1: ICMP echo reply, seq 1
[seq 2-4 identical pattern, source 192.168.122.1 throughout]

Root cause: I mistakenly believed I was running the ping from the training VM to test training-vm -> CentOS 9 (192.168.122.207) connectivity, but I had actually executed the command on the hypervisor (Ubuntu, ibnb-Latitude-E7240), so the test only proved hypervisor -> CentOS 9 connectivity, not connectivity between the two VMs.

Evidence: The initial tcpdump -i virbr0 capture showed ICMP packets with source IP 192.168.122.1 when the ping was expected to originate from 192.168.122.227, revealing a mismatch between expected and actual source address, later confirmed definitively by running hostname in each terminal.

What changed vs what stayed the same:
- Network state: unchanged (bridge, routes, ARP tables, interfaces identical throughout)
- Mental model: changed (corrected false belief about test origin)

Fix applied:
1. Noticed source-IP mismatch in tcpdump vs. expected origin
2. Questioned the assumption instead of assuming the network was broken
3. Ran hostname in each terminal to verify actual execution context
4. Confirmed ping had been issued from the hypervisor, not training-vm
5. Switched to the confirmed training-vm terminal
6. Repeated ping from verified context
7. Confirmed via tcpdump that source now matched training-vm's real IP (192.168.122.227)

Automated or permanent version of the fix: Hostname-bearing, color-coded PS1 prompts per machine (distinct colors for hypervisor vs. each VM), plus distinct terminal window titles, so execution context is visible on sight -- not dependent on reading text or remembering to check.

What would have caught this faster (detection gap): Should have verified execution context (hostname + ip -br a for source IP) before trusting the first ping result. That single check would have caught the wrong-shell error in seconds instead of several exchanges of investigation.
