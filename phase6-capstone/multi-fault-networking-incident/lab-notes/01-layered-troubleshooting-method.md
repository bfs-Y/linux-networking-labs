# Lab Notes: Multi-Fault Incident - Layered Troubleshooting Method
Topic: Blind, cold diagnosis of multiple independent, unrelated faults

--- THE ACTUAL INVESTIGATION ORDER, AND WHY IT WORKED ---
Interface -> IPv4 config -> DHCP -> ACD -> routing -> listening ports
-> application response -> upstream -> process internals -> end-to-end
verification from an independent client.
This order matters because each layer is a cheap, fast check that
either clears an entire category of suspicion or narrows it - same
principle as the 502-diagnosis order established back in the
loadbalancer topic (check backend health before assuming proxy config
is wrong), just extended across more layers here.

--- "LISTENING" IS NOT "HEALTHY" - PROVEN TWICE IN ONE INCIDENT ---
Two completely different failure modes both hid behind a technically-
correct-looking state:
1. Interface link-up with no IPv4 - NetworkManager reported "connected"
   while genuinely nothing usable existed at the IP layer.
2. A listening TCP port (8081/8082) that accepted connections but
   never returned a response, because the failure was inside the
   process (a logging write failing with EIO), not at the socket
   level at all.
Neither failure would show up in a naive "is it up" check
(nmcli status, ss -lntp) - both required going one layer deeper
(nmcli's detailed ipv4 fields; strace on the actual request handling).

--- strace AS A LAST-RESORT, HIGH-VALUE TOOL ---
When a service is confirmed listening, confirmed reachable, and still
fails - and the failure isn't visible in application logs alone -
strace on the live process during a real request is what actually
exposed the true mechanism here: recvfrom() succeeding, then write(2)
to stderr failing with EIO, then shutdown(). Checking
/proc/<pid>/fd/2 via readlink confirmed WHY: the fd pointed at a
pseudo-terminal that had already been deleted. This is a genuinely
non-obvious failure class - a process can be otherwise completely
healthy and still fail every single request because of what one of
its file descriptors points at.

--- DON'T DECLARE VICTORY AFTER THE FIRST FIX ---
After fixing the ACD/network fault, the application was STILL down -
a different, completely unrelated backend fault was still present.
The investigation correctly continued rather than stopping at "the
network works now." This is the actual defining trait of a genuine
multi-fault incident versus a single fault that merely presents with
several symptoms: fixing one root cause does not make the others
disappear, and only re-testing the full chain reveals whether more
work remains.

--- WHY nginx WASN'T THE PROBLEM, AND HOW THAT WAS PROVEN ---
A 502 from nginx means the proxy itself is fine; something behind it
isn't. Confirmed by checking nginx's own config (real upstream
addresses, correctly pointing at 8081/8082) and then testing those
backends directly, independent of nginx - exactly the "check the
backend before blaming the proxy" discipline from the earlier
loadbalancer topic, applied cold without being told to.

--- FINAL VERIFICATION MUST COME FROM AN INDEPENDENT VANTAGE POINT ---
Every fix was first verified locally (curl to 127.0.0.1), but the
incident was only actually considered closed after a successful
request from centos9 - a genuinely separate host, over the real
network path, not localhost. A local-only test can pass while the
real, external path remains broken (e.g. a firewall rule, as seen
in earlier phases) - this incident's final proof avoided that gap
deliberately.

--- PRODUCTION RELEVANCE ---
Real incidents are frequently NOT single clean root causes - multiple
unrelated things can and do break around the same time (a network
blip masking a pre-existing process bug that was never triggered
until then). Treating "found one plausible cause" as "incident
closed" without a full end-to-end re-test is a common, real mistake -
this investigation avoided it by design, continuing to test even
after the first fix appeared to work.
