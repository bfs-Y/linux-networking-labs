# Recall Practice — ICMP Rate-Limiting vs. Real Packet Loss

TOPIC: Distinguishing ICMP Rate-Limiting from Genuine Network Loss
DATE STARTED: 2026-08-20
TARGET: answer without checking reference — write the actual command.

DRILL 1 — A ping to a host shows 80% packet loss. Before concluding the
network path is broken, what single test would prove whether real
traffic through that same host is actually affected?
YOUR ANSWER:
>
REFERENCE:
curl -s -o /dev/null -w "HTTP %{http_code} in %{time_total}s\n" http://<host-ip>
(or any real TCP connection test to a service the host actually runs)

DRILL 2 — You want to deliberately rate-limit ICMP echo replies to
1/second on a host, dropping anything faster. Write the two iptables
commands, in the correct order, needed for this to actually take
effect on a ufw-managed host.
YOUR ANSWER:
>
REFERENCE:
sudo iptables -I INPUT 1 -p icmp --icmp-type echo-request -j DROP
sudo iptables -I INPUT 1 -p icmp --icmp-type echo-request -m limit --limit 1/second --limit-burst 1 -j ACCEPT
(insert DROP first so ACCEPT lands above it at position 1; -I, not -A,
so the rules run before ufw's own ICMP ACCEPT rule)

DRILL 3 — You added an ICMP rate-limit rule with `iptables -A` (append)
on a machine running ufw, but it has no effect at all -- pings still
succeed 100% of the time. What's the most likely reason, and what
command would confirm it?
YOUR ANSWER:
>
REFERENCE:
ufw's own before.rules file contains an unconditional ICMP echo-request
ACCEPT rule in the ufw-before-input chain, which is evaluated before
anything appended to the end of INPUT. Confirm with:
sudo iptables -L INPUT -v -n --line-numbers
(check whether your rule's position is before or after ufw-before-input)

DRILL 4 — Write the command to view the full INPUT chain with packet/
byte counters and line numbers, to diagnose exactly which rule is
matching (or not matching) traffic.
YOUR ANSWER:
>
REFERENCE: sudo iptables -L INPUT -v -n --line-numbers

SPEED ROUND — cover reference column, write the command aloud/on paper:

Test if real traffic works despite ping loss     -> curl -s -o /dev/null -w "%{http_code}\n" http://<ip>
Insert a rule at the very top of INPUT            -> iptables -I INPUT 1 ...
View chain with counters and line numbers         -> iptables -L INPUT -v -n --line-numbers
Send fast pings to test a rate limit              -> ping -c 10 -i 0.2 <ip>

WEAK SPOT LOG:
Date       | What I got wrong | Fixed?
