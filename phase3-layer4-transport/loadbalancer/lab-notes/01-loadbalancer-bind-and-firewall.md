# Lab Notes: Load Balancers - Correct Config Isn't Enough
Topic: nginx reverse proxy / round-robin load balancing
Repeat until the reasoning is automatic, not just the fix commands.

--- THE CORE LESSON ---
A load balancer can be internally perfect - nginx config valid, upstream
block correct, round-robin working - and still fail in production for two
completely different reasons that have nothing to do with the LB logic
itself: what the BACKENDS bind to, and what the FIREWALL allows.

--- WHY THIS MATTERS: TWO REAL FAILURE MODES, SAME SYMPTOM CLASS ---
Backends on 0.0.0.0: the whole point of a load balancer is to be the
single point of entry. If backends bind to all interfaces instead of
loopback, anyone on the network can hit them directly - no LB logic
applied, no centralized logging, no rate limiting, no single choke point
to secure. The LB becomes decorative, not authoritative.

Firewall never told about the LB's own port: nginx.conf and the app layer
can be flawless, and the service is still dead to the outside world if
the OS-level firewall never got a rule for the port nginx is listening
on. This is invisible from localhost - UFW's INPUT chain doesn't apply
to loopback traffic the same way, so testing only on the box itself will
never catch it.

A verify script that only checks localhost inherits both blind spots.
Verification that can't reach the failure mode isn't verification - it's
a false-positive generator.

--- PROVE IT ON THE WIRE ---
sudo ss -tulnp | grep <port>              # what's the KERNEL'S actual
                                             bind address - not what the
                                             process's own log claims
nc -zv <remote-ip> <port>                  # from a SECOND host, never
                                             from localhost - proves
                                             external reachability, not
                                             just "the process is alive"
sudo ufw status                            # is the port actually in the
                                             allow-list, or just assumed

A TCP timeout from a remote host has two distinct causes that look
identical from the client side: no listener on that interface, or a
listener exists but something silently drops the SYN. ss on the SERVER
distinguishes them - if ss shows the socket, the firewall is the suspect;
if it doesn't, no firewall is needed to explain the timeout.

--- PRODUCTION RELEVANCE ---
When standing up any new listening service, ask three separate questions,
not one: does the config work, does the process bind to the right
interface, and does the firewall know this port exists. All three can be
true or false independently - "it works" from localhost answers none of
them for real traffic.

--- NOT THE SAME AS WORKER PROCESSES ---
nginx master+workers share ONE socket because they're the same process
listening once. Load balancing is different: multiple SEPARATE, independent
servers/processes (possibly on different machines, different IPs), with a
proxy in front deciding which one gets each request. Don't conflate
"nginx has multiple worker processes" with "nginx is load balancing" -
they solve different problems at different layers.

--- CRITICAL LESSON: 502 BAD GATEWAY ---
502 means the PROXY is alive and working, but the BACKEND it tried to reach
refused or failed. Always check backend health FIRST when you see 502 -
don't assume the proxy config is wrong. Diagnosis order for any 502:
  1. ss -tulnp on each backend port - are they actually listening?
  2. systemctl status on the proxy itself - is IT actually running?
  3. nginx -t - is the current config even valid?
  4. Only after confirming proxy + config are healthy, suspect backend
     application logic.
This order matters because it goes from cheapest/fastest check to most
expensive - don't start debugging application code before ruling out
"is anything even listening."

--- CRITICAL LESSON: SILENT CONFIG FAILURES ---
A broken symlink (typo in filename) doesn't always fail loudly the moment
you create it. It can sit dormant until something later triggers a config
re-check (reload, restart, timer) - at which point the ENTIRE service can
go down, possibly hours later, with no immediate symptom at the time the
mistake was made. Always run `nginx -t` immediately after any config or
symlink change - never assume "no error now" means "no error ever."
