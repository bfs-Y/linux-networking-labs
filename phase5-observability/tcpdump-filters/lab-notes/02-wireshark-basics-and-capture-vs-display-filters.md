# Lab Notes: Wireshark Basics - Capture vs Display Filters
Topic: GUI packet analysis, non-root capture permissions, filter types

--- INSTALL AND PERMISSIONS: A REAL, VERIFIABLE DECISION ---
Wireshark's installer asks "should non-superusers be able to capture
packets?" - this isn't just a formality, it's a real security tradeoff.
Confirmed on this system (chose yes / accepted default):
  $ getcap /usr/bin/dumpcap
    /usr/bin/dumpcap cap_net_admin,cap_net_raw=eip
  $ groups
    training sudo wireshark
This grants packet-capture capabilities directly to the dumpcap
binary (the actual capture helper used by both wireshark and tshark),
scoped narrowly to just network capture - not full root access to the
whole GUI. Membership in the `wireshark` group is what makes this
apply to your user. This is the more secure design when available:
elevate only the specific capability needed, not the whole process.

--- GUI ON A VM: CHECK BEFORE ASSUMING HEADLESS ---
Assumed this machine might be headless (terminal/SSH only) before
checking. Confirmed otherwise:
  $ echo $XDG_SESSION_TYPE   -> wayland
  $ echo $DISPLAY            -> :0
A real graphical session was active. Don't assume a VM is headless -
check session type and DISPLAY variables directly before deciding to
fall back to a CLI-only tool (tshark) or a capture-then-transfer
workflow.

--- `which` CAN GIVE A FALSE NEGATIVE - VERIFY DIRECTLY ---
`which tshark` returned nothing even though tshark was genuinely
installed and functional - confirmed by running `tshark --version`
directly, which printed full version info. Don't trust `which`
returning empty as proof something is missing; cross-check with a
direct invocation of the command itself.

--- CAPTURE FILTERS vs DISPLAY FILTERS: DIFFERENT SYNTAX, DIFFERENT JOBS ---
Capture filter (BPF syntax, same as tcpdump): decides what gets
RECORDED in the first place, applied at capture start (e.g. selecting
an interface and optionally typing a BPF expression before starting).
Display filter (Wireshark's own syntax): decides what you SEE from
packets already captured, applied after the fact in the filter bar
at the top of the window (e.g. typing `dns` and pressing Enter).
Confirmed live: captured broadly on enp1s0 (DNS + ARP + whatever else
was happening), then used the display filter `dns` to narrow the
already-captured view down to only DNS packets, without needing to
re-capture. This is a real advantage over tcpdump's live-only
filtering - you can capture broad and decide what to look at later,
as long as you captured it in the first place.

--- PACKET DETAIL PANE SHOWS THE SAME DATA, DIFFERENT PRESENTATION ---
Expanding the "Domain Name System" section on a captured DNS response
packet showed the same fields already seen in raw `dig` output and
tcpdump text (transaction ID, TTL, answer records) - just presented
as an expandable tree instead of parsed manually from text. Same
underlying protocol structure; Wireshark's value is easier interactive
exploration, not different data.

--- PRODUCTION RELEVANCE ---
Capture broadly first when the exact traffic of interest isn't fully
known yet, then narrow with display filters during analysis - this
avoids missing something you didn't think to filter for at capture
time (a real risk with tcpdump's capture-time-only filtering, unless
you deliberately capture broad and post-filter with a saved pcap and
tools like tshark's -Y flag, which mirrors this same distinction on
the command line).
