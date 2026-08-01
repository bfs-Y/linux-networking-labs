TOPIC: Traffic analysis with tcpdump - proof, limitations, banner grabbing, pcap capture
DATE STARTED: 2026-08-01
TARGET: answer all drills without checking reference

DRILL 1 - You need to capture ONLY ICMP traffic on enp1s0, without DNS name resolution slowing the capture down. What's the command?
YOUR ANSWER:
>
REFERENCE:
sudo tcpdump -i enp1s0 -n icmp

DRILL 2 - A capture shows an ICMP echo request leaving your interface, with no matching echo reply ever appearing. What does this prove, and what can't it prove?
YOUR ANSWER:
>
REFERENCE:
Proves the request genuinely left your interface and no reply was ever seen on this end. Does NOT prove the packet was dropped by your own firewall, a router in between, or the destination - that requires a capture on the receiving end too.

DRILL 3 - Sender's app logs claim a request succeeded; receiver claims nothing arrived. What's the correct, defensible claim you can make from a sending-side tcpdump capture alone?
YOUR ANSWER:
>
REFERENCE:
"The request left this host, no reply was seen" - do not overclaim "it never reached them." Only state what your own capture actually proves; determining exactly where it died requires a capture on the receiving end.

DRILL 4 - You want to grab an SSH service's banner before authenticating, to see exactly what version it announces. What's the command?
YOUR ANSWER:
>
REFERENCE:
echo "" | nc -w 2 localhost 22

DRILL 5 - You've set VersionAddendum none in sshd_config and confirmed it's active with sudo sshd -T. The SSH banner still shows the Ubuntu distro patch suffix. Is this a misconfiguration?
YOUR ANSWER:
>
REFERENCE:
No - the distro suffix (e.g. "Ubuntu-3ubuntu13.16") is compiled into the binary at package build time, not reachable from sshd_config. This is a real, honest limitation, not a config mistake - mitigate by restricting who can reach the service and keeping it patched, not by chasing an unfixable config setting.

DRILL 6 - You need to save a live capture to disk for later analysis rather than watching it scroll past. What's the command, and what should you check before triggering the traffic you want captured?
YOUR ANSWER:
>
REFERENCE:
sudo tcpdump -i <if> -n tcp port <port> -w ~/capture.pcap & disown - then confirm it's actually running (e.g. sleep 2; ls -lh ~/capture.pcap) before triggering traffic, so you don't miss the start of the capture.

DRILL 7 - You SSH into your own machine using its real IP address (not 127.0.0.1). A capture on the physical interface (enp1s0) shows zero packets for that session. Is something broken?
YOUR ANSWER:
>
REFERENCE:
No - self-directed traffic to your own IP often resolves entirely through the loopback interface (lo), never touching the physical NIC even though a "real" IP was used. Capture on lo instead to see it.

DRILL 8 - A single saved pcap file contains traffic from multiple different SSH connection attempts made throughout the day. Can you assume all packets in the file belong to one session?
YOUR ANSWER:
>
REFERENCE:
No - a continuous capture doesn't separate sessions for you. Distinguish them by timestamp and by tracking SYN/FIN boundaries per conversation before drawing conclusions.

DRILL 9 - You start a capture with a brief delay before triggering the traffic you want to observe, intending to catch the full handshake. Is a short delay always sufficient to guarantee you see the connection's true start?
YOUR ANSWER:
>
REFERENCE:
No - if the handshake completes in the window right before or as tcpdump starts, you can genuinely miss it, even with a deliberate delay. For real investigations, continuous always-on capture is the only way to guarantee catching a connection's true beginning.

DRILL 10 - You're looking at a capture of established SSH traffic. What does the packet pattern look like, and why can't you read any commands or passwords in it?
YOUR ANSWER:
>
REFERENCE:
Small (~36 byte), uniform, rapid-fire packets in both directions - the encrypted keystroke rhythm of an interactive session. No readable content is visible because that's the actual security boundary SSH provides; a larger packet (~124 bytes) near the start is typically the key exchange/negotiation.

SPEED ROUND - cover reference column, answer aloud:
Capture only ICMP traffic, no DNS lookups -> sudo tcpdump -i <if> -n icmp
Capture only SSH traffic -> sudo tcpdump -i <if> -n tcp port 22
Grab an SSH banner before login -> echo "" | nc -w 2 localhost 22
Grab an HTTP server banner -> curl -I http://localhost
Check live active sshd config (not just the file) -> sudo sshd -T | grep -i <setting>
Save a capture to disk in the background -> sudo tcpdump -i <if> -n <filter> -w <file>.pcap & disown
Read a saved capture, first N packets only -> sudo tcpdump -r <file>.pcap -n -c <N>

WEAK SPOT LOG:
Date | What I got wrong | Fixed?
2026-08-01 | Original file mixed narrated reference content with drill labeling, no actual blank-recall testing | Y
