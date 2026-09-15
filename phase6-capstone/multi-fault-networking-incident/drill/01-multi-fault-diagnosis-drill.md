TOPIC: Multi-fault incident diagnosis - layered method, strace, independent verification
DATE STARTED: 2026-09-15
TARGET: answer all drills without checking reference

DRILL 1 - NetworkManager shows a connection as "connected" with DHCP
mode enabled, but the interface has no usable IPv4 address or route.
What command reveals this, and why doesn't a basic "is it connected"
check catch it?
YOUR ANSWER:
>
REFERENCE:
`nmcli -f ipv4.method,ipv4.addresses,ipv4.gateway,ipv4.dns connection
show <conn>` - the basic device/connection status only reports
connection state, not whether usable IP configuration was actually
installed. ACD or other DHCP-layer rejection can leave a connection
"active" with nothing usable underneath.

DRILL 2 - A DHCP client received Discover->Offer->Request->ACK for an
address, then logged an ACD conflict and declined it. What does this
sequence prove, and what does it NOT prove about why ACD rejected it?
YOUR ANSWER:
>
REFERENCE:
Proves the DHCP server and protocol exchange were functioning
correctly end to end. Does NOT by itself prove another host is
actively holding that IP - that requires separate evidence (ARP
testing, checking the DHCP lease table) before claiming a duplicate-IP
root cause.

DRILL 3 - A backend port shows LISTEN in `ss -lntp`, but every request
to it returns "Empty reply from server." What tool lets you see
exactly what the process does (or fails to do) while handling a real
request?
YOUR ANSWER:
>
REFERENCE:
strace -p <pid> -e trace=network,read,write -f - attach to the live
process and watch its actual syscalls during a request, rather than
inferring from external symptoms alone.

DRILL 4 - strace shows a process successfully receives a request
(recvfrom), then a write() to fd 2 fails with EIO, then the connection
is shut down. What's the next command to understand WHY that write
failed?
YOUR ANSWER:
>
REFERENCE:
sudo readlink /proc/<pid>/fd/2 - shows what fd 2 (stderr) actually
points to; a result like "/dev/pts/0 (deleted)" explains the EIO
directly (writing to a pseudo-terminal that no longer exists).

DRILL 5 - You fix the first fault you find in a multi-symptom incident
and the service still doesn't work. What's the correct next move?
YOUR ANSWER:
>
REFERENCE:
Keep investigating from where the symptom picture currently stands -
don't assume the first fix was insufficient or wrong; a genuinely
separate, unrelated second fault may simply still be present. Re-test
the full chain, don't declare victory on partial evidence.

DRILL 6 - You've fixed and verified a service locally on the affected
server (curl to 127.0.0.1 returns 200). Is the incident closed?
YOUR ANSWER:
>
REFERENCE:
Not yet - a local-only test can pass while the real network path
remains broken (firewall rule, wrong binding, etc.). Final
verification must come from a genuinely independent client host over
the real network path before considering an incident resolved.

SPEED ROUND - cover reference column, answer aloud:
Check real IPv4 config vs connection state -> nmcli -f ipv4.* connection show
Watch a live process's real syscalls -> strace -p <pid> -e trace=...
Check what an fd actually points to -> readlink /proc/<pid>/fd/<N>
"Listening" proves -> a socket exists, NOT that requests succeed
502 from a proxy means -> check the backend, not the proxy config first
Final proof of a fix -> test from an independent client, not just localhost

WEAK SPOT LOG:
Date | What I got wrong | Fixed?
