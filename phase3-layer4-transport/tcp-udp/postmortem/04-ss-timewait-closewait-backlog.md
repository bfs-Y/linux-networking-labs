Date: 2026-08-17
Lab: Phase 3 (Transport) - ss, TIME_WAIT, CLOSE_WAIT, and backlog, demonstrated live

Symptom (verbatim command and output):
Wanted to observe and prove, with real live evidence, four related
connection-state concepts on ubuntulab (Ubuntu 24.04): the ss tool
itself, TIME_WAIT (clean-close cooldown), CLOSE_WAIT (application not
closing its side), and backlog (the accept queue filling and
rejecting new connections).

Root cause: N/A - this was a demonstration/verification exercise, not
a fault investigation.

Evidence:

ss basics:
$ ss -tan
  -t (TCP only), -a (all sockets), -n (numeric, no DNS lookups).
  Shows LISTEN and ESTAB states on a live, normal system - real
  services (sshd on 22, a test web server on 80, CUPS on 631,
  systemd-resolved on 127.0.0.53/127.0.0.54) and two real ESTAB
  connections to external HTTPS servers.

TIME_WAIT - clean close cooldown:
$ for i in 1 2 3 4 5; do curl -s -o /dev/null http://localhost; done
$ ss -tan | grep -i wait
  5 distinct TIME-WAIT entries, one per curl invocation, each on a
  different local port. Confirms: after a normal, clean TCP close,
  the kernel holds that exact port pairing in a cooldown state,
  protecting against a late/stray packet from the old connection
  being mistakenly delivered into a new connection reusing the same
  port pairing too soon.

CLOSE_WAIT - application fails to close its side:
Built a minimal Python listener that accepts one connection then
sleeps, deliberately never calling close():
$ python3 -c "... s.listen(1); conn,addr = s.accept(); time.sleep(120)" &
$ echo "test" | timeout 1 nc localhost 9999
$ ss -tan | grep 9999
  CLOSE-WAIT 6  0  127.0.0.1:9999  127.0.0.1:<client-port>
  FIN-WAIT-2 0  0  127.0.0.1:<client-port>  127.0.0.1:9999
Confirms: the client sent its FIN and is waiting (FIN-WAIT-2) for the
server's FIN back. The server received the client's FIN (CLOSE_WAIT)
but its application code never called close() - the Recv-Q value of 6
shows real, unread data sitting in the socket buffer that the sleeping
application will never read. This is fundamentally an APPLICATION bug
signature, not a networking fault - in production, CLOSE_WAIT
connections accumulating and never clearing indicates a code path
that isn't closing sockets, which can eventually exhaust file
descriptors.

backlog - accept queue filling and rejecting new connections:
Built a minimal Python listener with a deliberately tiny backlog,
never calling accept() at all:
$ python3 -c "... s.listen(1); time.sleep(30)" &
$ ss -tan | grep 9999
  LISTEN 0 1 0.0.0.0:9999 0.0.0.0:*
  (Send-Q = 1 confirms the configured backlog size)

First connection (fits within backlog=1):
$ timeout 2 bash -c "echo test1 > /dev/tcp/localhost/9999"
  exit 0 (success)
$ ss -tan | grep 9999
  LISTEN 1 1 ... (Recv-Q now 1, queue full)

Second connection (exceeds the full backlog):
$ timeout 2 bash -c "echo test2 > /dev/tcp/localhost/9999"
  "Connection refused", exit 1
Confirms: a listening service can be fully up and healthy, yet refuse
new connections outright purely because its accept queue is full and
the application isn't draining it (calling accept()) fast enough -
a real, distinct failure mode from the service being down entirely.

Process note: an early attempt to fire 5 connections at once via a
bash for-loop with backgrounded subshells caused the Python listener
itself to disappear unexpectedly (confirmed via `jobs` showing empty
and `ss` showing nothing), despite the same listener code running
perfectly when tested alone in the foreground moments later. Root
cause of that specific shell-timing quirk was not identified - worked
around by testing one connection attempt at a time instead of a rapid
concurrent loop.

What changed vs what stayed the same:
Nothing persistent - all test listeners were temporary (background
Python processes), all cleaned up naturally by their own sleep
timers or by ending the connection attempts. No lasting config
changes.

Fix applied: N/A - demonstration exercise, no fault to fix.

Automated or permanent version of the fix: N/A. Real operational
takeaways:
- CLOSE_WAIT piling up = look at application code (missing close()
  calls), not the network.
- A listening service that refuses connections while otherwise
  appearing healthy may have a backlog exhaustion problem - check
  ss -tan's Send-Q (configured backlog) vs Recv-Q (current queue
  depth) on the LISTEN line to confirm.
- TIME_WAIT accumulating in very high volumes on a busy server can
  itself become a real capacity concern (each held port pairing
  consumes kernel resources) - worth monitoring on high-connection-
  churn services, though it is not itself a bug.

Detection gap: N/A - this was a deliberate, structured demonstration
with predictions checked against real evidence at each step.
