# Lab Notes: ss, TIME_WAIT, CLOSE_WAIT, and Backlog

## ss - the modern socket inspection tool
    ss -tan
-t = TCP only, -a = all sockets (listening + connected), -n = numeric
(skip DNS lookups). Shows State, Recv-Q, Send-Q, Local/Peer Address:Port.

## TIME_WAIT - deliberate cooldown after a clean close
After a normal TCP close (both sides exchange FIN/ACK), the side that
initiated the close holds the exact port pairing in TIME_WAIT for a
while before releasing it. This is NOT a bug or a stuck connection -
it protects against a late, straggling packet from the OLD connection
arriving after the port pairing gets reused, which could otherwise get
mixed into a brand-new connection's data.

Demonstrated:
    for i in 1 2 3 4 5; do curl -s -o /dev/null http://localhost; done
    ss -tan | grep -i wait
Produces 5 distinct TIME-WAIT entries, one per request, each on a
different local port (curl opens a fresh connection each time).

## CLOSE_WAIT - the local application hasn't closed its side
Different from TIME_WAIT: this means the REMOTE side already closed,
but the LOCAL application hasn't called close() on its socket yet.
Almost always an application bug signature, not a network problem.

Reproduced with a Python listener that accepts a connection and then
sleeps, deliberately never closing:
    s.listen(1)
    conn, addr = s.accept()
    time.sleep(120)   # never calls conn.close()

    echo "test" | timeout 1 nc localhost 9999
    ss -tan | grep 9999
    -> CLOSE-WAIT ... Recv-Q=6 (real unread data sitting in the buffer,
       an application that's sleeping will never read it)
    -> FIN-WAIT-2 on the client side (waiting for a FIN back that
       will never come until the server's application acts)

Production relevance: CLOSE_WAIT connections that accumulate and never
clear indicate a real application bug - a code path not calling
close() on sockets. Left unchecked, this eventually exhausts file
descriptors.

## backlog - the accept queue has a maximum size
When a connection arrives, it sits in a queue until the application
calls accept(). The backlog is the max size of that queue. If it
fills up, NEW connection attempts get refused outright - even though
the service is technically still up and listening.

    ss -tan | grep LISTEN
The Send-Q column on a LISTEN line shows the CONFIGURED backlog size.
The Recv-Q column shows how many connections are CURRENTLY queued.

Reproduced:
    s.listen(1)   # backlog of 1, server never calls accept()

First connection: succeeds, fills the queue (Recv-Q goes from 0 to 1,
matching Send-Q=1 - queue now full).
Second connection: "Connection refused" - queue was already full.

Production relevance: a service that refuses connections while
otherwise appearing healthy (process running, port open) may have a
backlog exhaustion problem, not a crash - check ss -tan's Send-Q vs
Recv-Q on the LISTEN line to confirm before assuming the service is
actually down.

## Lesson
TIME_WAIT and CLOSE_WAIT look similar at a glance (both involve a
closing connection) but mean very different things: TIME_WAIT is
healthy caution after a clean close; CLOSE_WAIT is a stuck close
waiting on the local application. Backlog exhaustion is a third,
distinct failure mode - the service itself is fine, but its queue
for NEW connections is full because the application isn't draining
it fast enough. All three are diagnosable directly with ss -tan,
without guessing.
