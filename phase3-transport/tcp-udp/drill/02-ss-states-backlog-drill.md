TOPIC: ss, TIME_WAIT, CLOSE_WAIT, and backlog
DATE STARTED: 2026-08-20
TARGET: answer all drills without checking reference

DRILL 1 - What's the command to see all TCP sockets (listening and connected), numeric, no DNS lookups?
YOUR ANSWER:
>
REFERENCE:
ss -tan

DRILL 2 - You see several TIME-WAIT entries after making a batch of curl requests. Is this a problem?
YOUR ANSWER:
>
REFERENCE:
No - TIME_WAIT is a deliberate kernel safety cooldown after a clean close, protecting against a late/stray packet from the old connection being mistakenly delivered into a new connection reusing the same port pairing too soon.

DRILL 3 - A service shows several CLOSE-WAIT connections that never clear over time. What does this indicate, and where should you look for the fix?
YOUR ANSWER:
>
REFERENCE:
An application bug - the remote side closed, but the local application never called close() on its socket. Look at the application's code (missing close() calls), not the network.

DRILL 4 - On a LISTEN line in ss -tan output, what do the Send-Q and Recv-Q columns represent?
YOUR ANSWER:
>
REFERENCE:
Send-Q = the configured backlog (max queue size for unaccepted connections). Recv-Q = how many connections are currently queued, waiting to be accepted.

DRILL 5 - A service's backlog is full. A new client tries to connect. What happens, even though the service process is running fine?
YOUR ANSWER:
>
REFERENCE:
The connection is refused outright ("Connection refused") - the service appears down to that client even though the process is healthy and the port is open. The real problem is the application isn't calling accept() fast enough to drain the queue.

DRILL 6 - You suspect a service is refusing connections due to backlog exhaustion rather than actually being down. What single command would you check to confirm?
YOUR ANSWER:
>
REFERENCE:
ss -tan | grep LISTEN - compare Recv-Q (current queue depth) against Send-Q (max backlog) for that port; Recv-Q at or near Send-Q confirms a full queue.

SPEED ROUND - cover reference column, answer aloud:
Show all TCP sockets, numeric -> ss -tan
Filter ss output for wait states -> ss -tan | grep -i wait
Check a specific port's socket states -> ss -tan | grep <port>
Find the PID of a process listening on a port -> sudo lsof -ti tcp:<port> -sTCP:LISTEN
Kill a stuck process by PID -> kill <pid>

WEAK SPOT LOG:
Date | What I got wrong | Fixed?
2026-08-20 | A rapid-fire bash for-loop with backgrounded subshells caused a test listener to disappear unexpectedly - root cause of that specific shell-timing issue never identified | N
