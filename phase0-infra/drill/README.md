# Daily Drill — Phase 0 Infrastructure & Operational Discipline

TOPIC: Wrong-Shell Diagnosis, PS1 Hardening, and Baseline Automation
DATE STARTED: 2026-07-11
TARGET: answer all drills without checking reference — write the
        actual command you would type, not a description of it.

DRILL 1 — A ping to a peer VM succeeds with 0% loss, but you're not
sure which machine actually ran it. Write the exact command to
prove, from a capture, which host originated the traffic.
YOUR ANSWER (write the command):
>
REFERENCE:
tcpdump -i virbr0 -n host <target-ip>
Compare the source IP in captured packets against each host's known
address — the capture is ground truth, the prompt is not.

DRILL 2 — Confirm two VMs share a Layer 2 broadcast domain before
treating "no connectivity" as a routing problem. Write both
commands, in order, and what you're checking in each output.
YOUR ANSWER (write both commands):
>
REFERENCE:
virsh domiflist <vm-name>
  -> check which "Source" network each vnet belongs to
ip link show <vnetX>
  -> check "master <bridgeN>" to confirm both vnets share a bridge

DRILL 3 — getcap shows a capability on a binary in one terminal, but
not in another. Write the two commands to check before assuming the
capability was lost.
YOUR ANSWER (write both commands):
>
REFERENCE:
stat --format="%d:%i" /path/to/binary
  -> run in both terminals, compare output -- confirms same file
hostname
  -> run in both terminals, confirms same machine

DRILL 4 — tcpdump fails with "You don't have permission to perform
this capture on that device" despite setcap being applied. Write the
command to check if AppArmor is confining the binary, and the
command to confirm an actual denial occurred.
YOUR ANSWER (write both commands):
>
REFERENCE:
sudo aa-status | grep tcpdump
sudo journalctl -k --since "10 min ago" | grep -i apparmor

DRILL 5 — ssh-copy-id to a host fails instantly with "Permission
denied (publickey)," no password prompt. Write the command to check
what's actually configured on the target's sshd.
YOUR ANSWER (write the command):
>
REFERENCE:
sudo grep -E "^PasswordAuthentication" /etc/ssh/sshd_config
(run on the target host)

DRILL 6 — SSH gets "Connection refused" after several failed
attempts, even though sshd is confirmed running. Write the command
to check for a fail2ban block, and the command to clear it.
YOUR ANSWER (write both commands):
>
REFERENCE:
sudo fail2ban-client status sshd
sudo fail2ban-client set sshd unbanip <your-ip>

DRILL 7 — A bash script under set -euo pipefail dies silently right
after `wait "$PID"` for a process killed on purpose by timeout.
Write the corrected code block that fixes this.
YOUR ANSWER (write the code):
>
REFERENCE:
if wait "$PID"; then
  EXIT_CODE=0
else
  EXIT_CODE=$?
fi
if [ "$EXIT_CODE" -ne 0 ] && [ "$EXIT_CODE" -ne 124 ]; then
  echo "ERROR: unexpected exit $EXIT_CODE" >&2
  exit 1
fi

DRILL 8 — You need to let a capture tool run without root, using the
least standing privilege. Write the exact command to grant it.
YOUR ANSWER (write the command):
>
REFERENCE:
sudo setcap cap_net_raw,cap_net_admin=eip /usr/bin/tcpdump

SPEED ROUND — cover reference column, write the command aloud/on paper:

Confirm which machine a terminal is on            -> hostname
Prove traffic crossed the bridge                   -> tcpdump -i virbr0 -n host <ip>
Map a VM's vnet to its libvirt network              -> virsh domiflist <vm>
Check if a capability landed on a binary            -> getcap /path/to/binary
Check if AppArmor confines a binary                 -> sudo aa-status | grep <binary>
Check for an active fail2ban ban on your own IP     -> sudo fail2ban-client status <jail>
Force fresh ARP resolution and observe it           -> ip neigh del <ip> dev <if>  &&  sudo tcpdump -i <if> arp
Test passwordless SSH without hanging on a prompt   -> ssh -o BatchMode=yes -o ConnectTimeout=3 <user>@<ip> echo ok
Grant a tool raw-capture capability, no root         -> sudo setcap cap_net_raw,cap_net_admin=eip <path>
Check inode identity of two file paths              -> stat --format="%d:%i" <path>

WEAK SPOT LOG:
Date       | What I got wrong                                          | Fixed?
2026-07-10 | Trusted a ping result without confirming execution context | Yes
2026-07-10 | Assumed AppArmor was cause without checking logs first     | Yes
2026-07-11 | Ran setcap on wrong host (VM instead of hypervisor)        | Yes
2026-07-11 | Used || true instead of understanding set -e's real rule   | Yes
