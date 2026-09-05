TOPIC: Wireshark basics, capture vs display filters, non-root capture permissions
DATE STARTED: 2026-09-05
TARGET: answer all drills without checking reference

DRILL 1 - Wireshark's installer asks "should non-superusers be able to
capture packets?" What does choosing "yes" actually do at the system
level - grant full root to the GUI, or something narrower?
YOUR ANSWER:
>
REFERENCE:
Something narrower - it grants specific capabilities (cap_net_admin,
cap_net_raw) directly to the dumpcap binary (the capture helper), and
adds your user to the wireshark group. This is not the same as
running the whole GUI as root.

DRILL 2 - What two environment variables would you check to confirm a
Linux machine has an active graphical session, before assuming it's
headless and reaching for a CLI-only tool?
YOUR ANSWER:
>
REFERENCE:
$XDG_SESSION_TYPE and $DISPLAY - non-empty values indicate an active
graphical session.

DRILL 3 - `which tshark` returns nothing, but you suspect it might
still be installed. What do you run to check directly, rather than
trusting `which`'s empty result?
YOUR ANSWER:
>
REFERENCE:
tshark --version (or similar direct invocation) - `which` can give a
false negative; a direct call confirms whether the binary actually
works.

DRILL 4 - What's the difference between a tcpdump/Wireshark CAPTURE
filter and a Wireshark DISPLAY filter?
YOUR ANSWER:
>
REFERENCE:
A capture filter (BPF syntax) decides what gets recorded at capture
time. A display filter (Wireshark's own syntax) decides what you see
from packets already captured - applied after the fact, doesn't
require re-capturing.

DRILL 5 - You captured broadly on an interface with no capture filter
at all, and now want to see only DNS traffic from what you recorded.
What do you type in Wireshark's filter bar?
YOUR ANSWER:
>
REFERENCE:
dns (Wireshark's own simple protocol-name syntax, different from
tcpdump's `udp port 53` BPF syntax)

DRILL 6 - Why is "capture broad, then filter with a display filter"
sometimes a real advantage over tcpdump's capture-time-only filtering?
YOUR ANSWER:
>
REFERENCE:
If you don't yet know exactly what traffic you need to see, a narrow
capture filter risks missing it entirely. Capturing broadly and
filtering afterward means nothing is lost, as long as it was captured
in the first place.

SPEED ROUND - cover reference column, answer aloud:
Check for an active graphical session -> $XDG_SESSION_TYPE, $DISPLAY
Verify a command exists despite `which` returning nothing -> run it directly, e.g. --version
Capture filter syntax -> BPF (same as tcpdump, e.g. udp port 53)
Display filter syntax -> Wireshark's own, e.g. dns
Non-root capture permission mechanism -> capabilities on dumpcap + wireshark group membership

WEAK SPOT LOG:
Date | What I got wrong | Fixed?
2026-09-05 | Assumed `which tshark` returning empty meant tshark wasn't installed - it was, confirmed via `tshark --version` | Y
