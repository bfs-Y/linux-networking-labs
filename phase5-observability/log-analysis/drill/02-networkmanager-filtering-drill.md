TOPIC: journalctl unit scoping, priority filtering, time windows, multi-finding triage
DATE STARTED: 2026-09-05
TARGET: answer all drills without checking reference

DRILL 1 - `journalctl -u NetworkManager` (no sudo) returns "No
entries." What should you check before concluding NetworkManager
never logged anything?
YOUR ANSWER:
>
REFERENCE:
Your group membership (`groups`) - users need to be in `adm` or
`systemd-journal` to see full system logs without sudo. An empty
result can mean "no access," not "nothing happened."

DRILL 2 - What flag scopes journalctl output to ONE specific systemd
unit's own log stream?
YOUR ANSWER:
>
REFERENCE:
-u <unit-name> (e.g. -u NetworkManager)

DRILL 3 - What flag filters journalctl output to only warning-level
(or more severe) entries, cutting out routine info-level noise?
YOUR ANSWER:
>
REFERENCE:
-p warning

DRILL 4 - What flags let you narrow journalctl output to a specific
time window, once you've identified a candidate event to investigate
closely?
YOUR ANSWER:
>
REFERENCE:
--since "<time>" --until "<time>"

DRILL 5 - A recurring warning appears at nearly every boot for over a
year, but was never noticed before. What's the actual test for
whether this is a real problem worth fixing, versus expected noise?
YOUR ANSWER:
>
REFERENCE:
Investigate what the warning actually claims (research the specific
message/file if unfamiliar) rather than assuming either "it's been
there forever so it's fine" or panicking. In this case: researching
the netplan permissions warning against official docs confirmed it
was a genuine, actionable security gap (chmod 600 needed).

DRILL 6 - Repeated OpenVPN connection failures appear across many
days in the logs. What's the deciding question for whether this is
an incident requiring action?
YOUR ANSWER:
>
REFERENCE:
Does the operator recognize and expect this activity? If it's known,
intentional usage (manually starting/stopping VPN connections), it's
expected noise, not an incident - regardless of how alarming the
error text looks.

DRILL 7 - A network interface shows a ~9 hour logging gap followed by
a full DHCP re-negotiation (not a simple renewal). What operational
event commonly explains this pattern, other than a real network fault?
YOUR ANSWER:
>
REFERENCE:
A suspend/resume cycle - the VM being suspended (not shut down) for
that window naturally produces exactly this signature, since lease/
session state isn't cleanly carried across the suspend.

SPEED ROUND - cover reference column, answer aloud:
Scope logs to one systemd unit -> journalctl -u <unit>
Filter to warnings and above -> journalctl -p warning
Narrow to a specific time window -> --since / --until
Empty journalctl result without sudo, meaning? -> check group membership first
Deciding test for any log finding -> does the operator recognize/expect this activity
Netplan YAML file recommended permissions -> chmod 600 (root read/write only)

WEAK SPOT LOG:
Date | What I got wrong | Fixed?
