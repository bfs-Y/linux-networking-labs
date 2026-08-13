TOPIC: TCP vs UDP tradeoff, handshake mechanics, and failure diagnosis
DATE STARTED: 2026-08-09
TARGET: answer all drills without checking reference

DRILL 1 - TCP guarantees ordered, complete delivery; UDP guarantees nothing. In a live video call, one frame is lost. Which protocol handles this better, and why?
YOUR ANSWER:
>
REFERENCE:
UDP - TCP would freeze playback waiting for the lost piece to be resent, even though newer data already arrived. UDP just skips it - a brief glitch beats a freeze for live media.

DRILL 2 - An SSH command has one packet corrupted or lost in transit. Which protocol is correct here, and why does the same tradeoff produce the opposite conclusion from DRILL 1?
YOUR ANSWER:
>
REFERENCE:
TCP - a half-second stall is a minor cost compared to a corrupted command silently executing on a remote shell. Correctness is non-negotiable here, unlike a video frame.

DRILL 3 - Write the tcpdump commands to prove the TCP vs UDP packet-count difference for a DNS lookup vs an HTTP request.
YOUR ANSWER:
>
REFERENCE:
sudo tcpdump -i <if> -n udp port 53   (then run: dig <domain>)
sudo tcpdump -i <if> -n tcp port 80   (then run: curl http://<site>)

DRILL 4 - What are the three packets of a TCP handshake, and their flags?
YOUR ANSWER:
>
REFERENCE:
SYN [S] -> SYN-ACK [S.] -> ACK [.]

DRILL 5 - After a SYN with seq X, why does the SYN-ACK's ack field equal X+1?
YOUR ANSWER:
>
REFERENCE:
SYN consumes one sequence number even though it carries no data - ack means "next byte expected," so it's seq + 1.

DRILL 6 - What does the PUSH flag [P.] mean, and why does it never appear during the handshake itself?
YOUR ANSWER:
>
REFERENCE:
PUSH means "deliver to the application immediately, don't buffer" - appears on packets carrying real data. The handshake carries zero application data, so there's nothing to push yet.

DRILL 7 - What's the difference between a FIN and a RST?
YOUR ANSWER:
>
REFERENCE:
FIN = graceful close, both sides finish exchanging data first. RST = immediate abort - closed port, crashed app, or firewall block.

DRILL 8 - A connection to one target fails (only SYN packets, retransmitted, no SYN-ACK ever returned). How do you isolate whether the fault is local (your machine/network) or remote (the target)?
YOUR ANSWER:
>
REFERENCE:
Test a known-working destination on the same path/protocol first. If the known-good target works but the failing one doesn't, the fault is isolated to at/near the target, not your local setup.

SPEED ROUND - cover reference column, answer aloud:
Capture a DNS lookup -> sudo tcpdump -i <if> -n udp port 53
Capture an HTTP request -> sudo tcpdump -i <if> -n tcp port 80
SYN-ACK combined flags -> SYN + ACK
Graceful close flag -> FIN
Immediate abort flag -> RST
Data-carrying packet flag -> PUSH (P.)

WEAK SPOT LOG:
Date | What I got wrong | Fixed?
2026-08-09 | Original drill file mixed reference content with drill labeling, answers shown directly under questions with no blank-recall step | Y
2026-08-09 | break/02-tcp-handshake-capture.sh had a real timing bug (fixed sleep, no verification) causing 0 packets captured | Y
