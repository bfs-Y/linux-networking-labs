TOPIC: Load balancer bind-address and firewall failure modes
DATE STARTED: 2026-08-22
TARGET: answer all drills without checking reference

DRILL 1 - A load balancer's backends are supposed to only be reachable
through the LB. What Python http.server flag ensures a backend doesn't
bind to all interfaces, and what's the default if you omit it?
YOUR ANSWER:
>
REFERENCE:
-b ADDRESS / --bind ADDRESS. Default with it omitted is "all interfaces"
(0.0.0.0) - meaning the backend is directly reachable, bypassing the LB.

DRILL 2 - nginx is confirmed listening on 0.0.0.0:8090 via ss, but a
remote host gets a connection timeout hitting that port. ss shows the
listener exists. What's the next command to check, and why?
YOUR ANSWER:
>
REFERENCE:
sudo ufw status (or iptables -L -n) - if the listener exists but the
connection still times out, the firewall is the remaining candidate
cause; ss already ruled out "no listener."

DRILL 3 - Why does testing a load balancer only from localhost fail to
catch a missing firewall rule for that same port?
YOUR ANSWER:
>
REFERENCE:
UFW's INPUT chain governs traffic arriving from the network - traffic
that never leaves the box (localhost-to-localhost) doesn't traverse
those rules the same way, so a missing external rule is invisible from
the box itself.

DRILL 4 - Two hosts, ubuntulab and centos9, share a subnet. You want to
prove a backend on ubuntulab is NOT reachable except through the LB.
Why is `curl 127.0.0.1:8081` on ubuntulab itself insufficient proof?
YOUR ANSWER:
>
REFERENCE:
Loopback is reachable from localhost by definition, regardless of any
bind restriction or firewall rule - it proves nothing about external
reachability. The real test has to originate from a second host.

DRILL 5 - A TCP connection attempt from a remote host either times out
or gets "connection refused" almost instantly. What's the difference in
what actually happened at the network layer for each?
YOUR ANSWER:
>
REFERENCE:
Refused = a RST came back fast, meaning something actively answered and
rejected. Timeout = no response at all - no listener there, or a
firewall silently dropped the SYN with no reply.

DRILL 6 - You scope a UFW rule with `from 192.168.122.0/24 to any port
8090 proto tcp` instead of just `allow 8090/tcp`. Why does the scoping
matter here?
YOUR ANSWER:
>
REFERENCE:
Unscoped opens the port to any source, including the public internet if
the box has any other route. Scoping to the lab subnet limits exposure
to only the hosts that actually need it - least privilege applied to a
firewall rule, not just to user accounts.

DRILL 7 - The pre-existing verify script only tests curl against
localhost:8090. Why does it pass even when both real defects (0.0.0.0
backends, missing UFW rule) are present?
YOUR ANSWER:
>
REFERENCE:
Because localhost bypasses both failure modes entirely - loopback
traffic doesn't need the UFW external rule, and testing 8090 through
nginx from the same box never exercises the bind restriction on the
backends. A verify script's blind spots are exactly its untested paths.

SPEED ROUND - cover reference column, answer aloud:
Backend binds to all interfaces by default -> missing -b/--bind flag
Kernel-confirmed bind address command -> sudo ss -tulnp
Cross-host port reachability test -> nc -zv <ip> <port>
Firewall allow-list check -> sudo ufw status
Timeout vs refused -> no response/dropped vs active RST
Fastest way to fool yourself testing an LB -> testing only from localhost

WEAK SPOT LOG:
Date | What I got wrong | Fixed?
2026-08-22 | Ran nc -zv and curl on one line, assumed nc's timeout wouldn't block the curl from running in the same command chain | Y
2026-08-22 | Attempted to skip cross-host verification and treat localhost success as sufficient proof the fix worked | Y
