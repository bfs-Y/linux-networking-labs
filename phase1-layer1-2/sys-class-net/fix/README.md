# Fix: N/A - self-resolving

This scenario (UDP flood via iperf3 to stress rx_dropped) requires no
fix script. iperf3's -t 10 flag runs the flood for exactly 10 seconds
and then exits on its own - no config, rule, or persistent state is
changed by break/01-udp-flood-rx-dropped.sh. Once the command
completes, the interface returns to normal traffic levels with no
manual intervention required.

If rx_dropped remains elevated significantly after the flood ends
(i.e. new drops accumulated during the test and never age out or
reset), that is expected - the counter is cumulative since interface
initialization and does not automatically decrement. Use a fresh
before/after delta on the NEXT test to measure new drops, rather than
expecting the absolute value to return to its pre-flood baseline.
