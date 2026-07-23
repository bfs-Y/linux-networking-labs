# Lab Notes: iperf3 Connectivity Failure (firewalld-blocked port)

## Objective
Determine why a client VM cannot connect to an iperf3 server when the
underlying network (route, ARP) is healthy.

Expected root cause: centos9 firewalld missing TCP/5201.

## Procedure

### 1. Start the server (centos9)
    iperf3 -s
Expected: "Server listening on 5201"
What this proves: the application is listening on TCP port 5201.
Keep this terminal open.

### 2. Break the system (centos9, separate terminal)
    ./phase1-layer1-2/ethtool/break/01-remove-iperf3-firewall-rule.sh
Verify:
    sudo firewall-cmd --list-all
Expect NOT to see "5201/tcp" under ports:.
From here, treat the cause as unknown and diagnose from symptom only.

### 3. Reproduce the failure (training-vm)
    iperf3 -c 192.168.122.207
Expected: "No route to host" — this is the symptom, not the cause.
Do not jump straight to the firewall.

### 4. Investigation sequence (training-vm unless noted)

A. Route:
    ip route get 192.168.122.207
   Confirms the kernel knows how to reach the server.

B. Neighbor:
    ip neigh show 192.168.122.207
   Confirms Layer 2 resolution — expect REACHABLE or STALE, valid MAC.

C. Server-side firewall (centos9):
    sudo firewall-cmd --list-all
   Check "ports:" — 5201/tcp missing is the actual finding.

D. Service listening check (centos9):
    ss -tlnp | grep 5201
   Confirms iperf3 itself is actually listening, independent of firewall.

Result pattern:
    Route       correct
    Neighbor    correct
    Service     listening
    Firewall    blocking  <- actual fault

### 5. Apply the fix (centos9)
    ./phase1-layer1-2/ethtool/fix/01-restore-iperf3-firewall-rule.sh

### 6. Verify recovery (training-vm)
    iperf3 -c 192.168.122.207
Expected: connects, reports throughput.

## Mental model
Client -> Route? -> ARP/MAC? -> TCP/5201 -> Server
                                              -> listening? (ss -tlnp)
                                              -> firewall allows? (firewall-cmd)

## Lesson
A missing firewall rule and a real throughput problem produce different
symptoms. "No route to host" from a connection attempt is a hard
rejection, not degraded performance — always check firewall/service
state on the *destination* before assuming a Layer 1/2 or performance
issue on the source.
