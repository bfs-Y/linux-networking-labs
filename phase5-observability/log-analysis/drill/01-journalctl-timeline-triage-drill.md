TOPIC: journalctl boot scoping, timeline reconstruction, block-event triage
DATE STARTED: 2026-09-05
TARGET: answer all drills without checking reference

DRILL 1 - What journalctl flags show only kernel messages from the
CURRENT boot session, excluding logs from previous reboots?
YOUR ANSWER:
>
REFERENCE:
-k -b (e.g. `sudo journalctl -k -b`)

DRILL 2 - How do you actually reconstruct an incident timeline from
raw journalctl output - what special tool or technique is required?
YOUR ANSWER:
>
REFERENCE:
No special tool - read entries in chronological order (their natural
order in journalctl output) and correlate timestamps across
seemingly unrelated log lines. The skill is careful reading, not a
specific command.

DRILL 3 - A [UFW BLOCK] log entry shows traffic to UDP port 3702,
multicast address 239.255.255.250, sourced from your own machine.
What's the first thing to do before deciding if this is a problem?
YOUR ANSWER:
>
REFERENCE:
Identify what the port/protocol actually is (research it, e.g. WS-
Discovery for port 3702) rather than assuming it's either malicious
or automatically fine based on how it looks.

DRILL 4 - After identifying a blocked protocol, what's the actual
question that determines whether it's a real problem or expected
noise?
YOUR ANSWER:
>
REFERENCE:
Does this specific machine/environment have any legitimate need for
that traffic? If not, a block is correct, expected behavior - not
an incident requiring action.

DRILL 5 - Name the general 4-step pattern for triaging any logged
"block" event, as used on the WS-Discovery finding this session.
YOUR ANSWER:
>
REFERENCE:
1) Identify exactly what's being blocked (source/dest/port/protocol).
2) Research unfamiliar ports/protocols rather than guessing.
3) Ask if the environment legitimately needs that traffic - if not,
   the block is correct and expected.
4) Only escalate if something genuinely needed is what's being
   blocked (the inverse case: correctly-allowed-but-not-running,
   seen earlier this phase with Cockpit).

DRILL 6 - Why is "pattern-matching on scary-looking words like BLOCK"
the wrong approach to real log-based incident response?
YOUR ANSWER:
>
REFERENCE:
Most logged "block" events in a real environment are routine, harmless
background noise (multicast discovery protocols, broadcast traffic) -
the actual skill is triaging each finding against what the environment
needs, not reacting to alarming-sounding log text.

SPEED ROUND - cover reference column, answer aloud:
Scope kernel logs to current boot -> journalctl -k -b
How to build a timeline -> read chronologically, correlate timestamps
First step when triaging a block event -> identify what's actually being blocked
Deciding factor: problem or noise -> does the environment legitimately need this traffic
WS-Discovery port -> 3702 (UDP/TCP, multicast 239.255.255.250 / ff02::c)

WEAK SPOT LOG:
Date | What I got wrong | Fixed?
