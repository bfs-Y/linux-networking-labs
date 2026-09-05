TOPIC: Nmap scanning basics - privilege effects, port states, service verification
DATE STARTED: 2026-09-05
TARGET: answer all drills without checking reference

DRILL 1 - You run `nmap <ip>` without sudo and it reports "host seems
down," but a direct ping to that IP succeeds with 0% loss. What's the
most likely explanation?
YOUR ANSWER:
>
REFERENCE:
Unprivileged Nmap can't send real ICMP echo probes - it falls back to
TCP SYN connect() probes on ports 80/443 only. If the target doesn't
expose anything on those ports, those probes get no response and
Nmap concludes "down," even though ICMP genuinely works.

DRILL 2 - What are Nmap's four default host-discovery probes when run
with full (root) privileges?
YOUR ANSWER:
>
REFERENCE:
ICMP echo request, TCP SYN to port 443, TCP ACK to port 80, and ICMP
timestamp request.

DRILL 3 - What's the difference between a "filtered (no-response)"
port and a "filtered (admin-prohibited)" port?
YOUR ANSWER:
>
REFERENCE:
no-response = the firewall silently drops the probe, no reply at all
(a timeout). admin-prohibited = the firewall actively sends an ICMP
message explicitly rejecting the probe (an active rejection).

DRILL 4 - A port shows as CLOSED (not filtered). What does that
actually tell you about what happened during the scan?
YOUR ANSWER:
>
REFERENCE:
The probe reached the host successfully (the firewall let it through)
- but nothing was listening on that port to accept a connection.
Different from filtered, where the firewall itself blocks the probe
before it reaches a listening/non-listening socket at all.

DRILL 5 - Nmap's default scan labels port 9090 as "zeus-admin." Is
that a verified identification of what's running there?
YOUR ANSWER:
>
REFERENCE:
No - it's a guess from Nmap's static port-number database, which can
be stale or wrong. Real identification requires -sV (version
detection, which actually probes and reads the service's response)
or direct knowledge/verification on the host itself.

DRILL 6 - A firewall (firewalld) explicitly lists a service (e.g.
cockpit) as allowed, but a scan shows that service's port as CLOSED,
not open. What should you check on the host itself before assuming
the firewall config is wrong?
YOUR ANSWER:
>
REFERENCE:
Whether the actual service/socket unit is running - e.g. `systemctl
status cockpit.socket`. A firewall rule allowing traffic doesn't mean
the service behind it is actually started; both layers (firewall +
service state) must be correct independently.

SPEED ROUND - cover reference column, answer aloud:
Unprivileged nmap default probe -> TCP SYN connect() to ports 80/443 only
Full-privilege default probes -> ICMP echo, TCP SYN/443, TCP ACK/80, ICMP timestamp
Silent firewall drop -> filtered (no-response)
Active firewall rejection -> filtered (admin-prohibited)
Port reachable but nothing listening -> closed
Verify a scanner's guessed service name -> -sV, or check directly on the host

WEAK SPOT LOG:
Date | What I got wrong | Fixed?
2026-09-05 | First unprivileged nmap scan reported host down; didn't immediately connect it to privilege level, needed to check Nmap's own documentation to find the real cause | Y
