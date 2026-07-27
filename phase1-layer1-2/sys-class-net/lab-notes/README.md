# Lab Notes: /sys/class/net Kernel Interface Statistics

## Objective
Use per-interface kernel statistics under /sys/class/net/<if>/statistics/
to diagnose reported packet loss with more granularity than ip -s link
show, and distinguish a live/ongoing fault from a static, historical, or
unattributed counter value.

## Investigation baseline
    ls /sys/class/net/enp1s0/statistics/
Lists all available kernel counters. Key ones for a receive-loss report:
    cat /sys/class/net/enp1s0/statistics/rx_errors
    cat /sys/class/net/enp1s0/statistics/rx_dropped

rx_errors = 0 rules out the entire hardware/driver error category
(rx_over_errors, rx_crc_errors, rx_frame_errors, rx_missed_errors) in
one check - no need to inspect each sub-counter individually once the
parent is confirmed zero.

rx_dropped nonzero means packets arrived intact (no hardware fault) but
were discarded somewhere in the receive path after arrival - commonly
by kernel-level policy (e.g. firewall default-drop) or genuine buffer/
queue exhaustion under real traffic pressure.

## Distinguishing live fault from static/historical counter
A nonzero counter alone does NOT prove an active, ongoing problem.
Kernel statistics are cumulative since interface initialization and
never reset on their own. Always run a controlled before/after test:

    cat /sys/class/net/enp1s0/statistics/rx_dropped   # before
    ping -c 20 <peer-ip>                                # generate traffic
    cat /sys/class/net/enp1s0/statistics/rx_dropped   # after

If before == after, no new drops occurred during that traffic pattern -
the existing count is historical/unattributed, not evidence of a live
fault with THIS traffic type. Ping alone will not exercise every
possible drop mechanism (e.g. a firewall rule scoped to specific ports),
so a clean ping delta rules out drops caused by ICMP specifically, not
all possible causes.

## Reproducing a real, measurable increment
Ping's small ICMP payload rarely stresses receive buffers enough to
cause genuine rx_dropped increments. To reproduce real buffer/queue
pressure, use a high-bitrate UDP flood - UDP has no flow control
(unlike TCP, which backs off under congestion), so it will keep
sending even if the receiver can't keep up.

Prerequisite - start the server on the RECEIVING host (whichever
host's rx_dropped you want to test):
    iperf3 -s
    # on ubuntulab (Ubuntu 24.04)

Then run the flood from the sending host:
    ./phase1-layer1-2/sys-class-net/break/01-udp-flood-rx-dropped.sh
    # run on centos9 (CentOS Stream 9)
Sends a 1Gbit/s UDP stream for 10 seconds at ubuntulab's enp1s0.

Check the delta on ubuntulab immediately before and after the flood
completes, same before/after method as above.

## Fix
None required - see fix/README.md. The flood is time-bounded
(iperf3 -t 10) and self-resolving; no config or persistent state is
changed by running it.

## Lesson
A cumulative kernel counter with a nonzero value is not, by itself,
evidence of an active fault. Always run a controlled before/after
comparison with real traffic before concluding causation - and be
specific about which traffic TYPE was tested, since a clean result
with one traffic pattern (e.g. ICMP) does not rule out drops caused
by a different pattern (e.g. a firewall rule scoped to specific ports,
or genuine high-volume UDP pressure).
