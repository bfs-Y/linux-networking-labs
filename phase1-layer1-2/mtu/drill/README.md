TOPIC: MTU mismatch diagnosis and reproduction
DATE STARTED: 2026-07-24
TARGET: answer all drills without checking reference

DRILL 1 - Small pings between two hosts succeed, but large file transfers hang or stall. What's your first hypothesis and what command tests it directly?
YOUR ANSWER:
>
REFERENCE:
MTU mismatch or path fragmentation issue. Test with ping -M do -s <size> - set the Don't Fragment bit and size the payload to the MTU boundary, so the path is forced to reveal a mismatch instead of silently fragmenting around it.

DRILL 2 - You want to test the full 1500-byte MTU with ping. What -s value do you pass, and why not 1500?
YOUR ANSWER:
>
REFERENCE:
-s 1472. ping's -s sets only the ICMP payload; total packet size also includes 8 bytes ICMP header + 20 bytes IP header = 28 bytes overhead. 1472 + 28 = 1500.

DRILL 3 - A DF-bit ping at full MTU size gets 0% loss on both endpoints, and a real large-file transfer completes without stalling. Does this rule out an MTU fault?
YOUR ANSWER:
>
REFERENCE:
Yes - both are direct, real evidence that full-size packets traverse the path unfragmented and undropped. No further MTU diagnosis is needed; look elsewhere for the reported symptom's actual cause.

DRILL 4 - You need to lower an interface's MTU to intentionally create a mismatch for testing. What command, and what should you do BEFORE running it?
YOUR ANSWER:
>
REFERENCE:
sudo ip link set dev <if> mtu <value> - but first read and save the CURRENT MTU (e.g. to a state file) so the fix can restore the exact original value instead of assuming a hardcoded default like 1500.

DRILL 5 - After lowering one host's MTU to 1400 (peer still at 1500), what specific test result would confirm the mismatch, and what would a plain ping show instead?
YOUR ANSWER:
>
REFERENCE:
A DF-bit ping sized to 1472 (testing 1500) from the peer would now fail. A plain, small ping (default ~56 bytes) would still succeed - that split (small works, large fails) is the actual MTU-mismatch signature.

DRILL 6 - You start a tcpdump capture, then realize you pressed Ctrl+C before starting the traffic you meant to observe. What's wrong with the resulting capture file, and what's the correct sequence?
YOUR ANSWER:
>
REFERENCE:
The capture recorded nothing of the intended traffic - it had already stopped before the traffic began. Correct sequence: start the capture, confirm it's actively running (separate terminal/session), THEN start the action being observed, then stop the capture.

SPEED ROUND - cover reference column, answer aloud:
Check configured MTU on an interface -> ip link show <if>
Set a new MTU on an interface -> sudo ip link set dev <if> mtu <value>
Test full-MTU unfragmented delivery -> ping -M do -s 1472 -c 4 <ip>
Generate a large test file fast -> dd if=/dev/zero of=<path> bs=1M count=<N>
Capture traffic on an interface to a file -> sudo tcpdump -i <if> -nn -s 0 -w <file> '<filter>'
Read a saved capture file -> sudo tcpdump -nn -r <file> '<filter>'

WEAK SPOT LOG:
Date | What I got wrong | Fixed?
2026-07-24 | Stopped tcpdump before starting the transfer it was meant to capture | Y
2026-07-24 | Chased a reported "hang" symptom without measuring it first (3rd time this pattern occurred tonight) | Y
