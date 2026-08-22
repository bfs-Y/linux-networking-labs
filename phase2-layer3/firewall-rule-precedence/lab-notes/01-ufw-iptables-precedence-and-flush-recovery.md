# Lab Notes -- ufw/iptables Rule Precedence and Safe Flush Recovery

Date: 2026-08-22

## Objective
Understand how ufw and raw iptables rules interact within the same
INPUT chain, why rule ORDER (not just presence) determines behavior,
and how to safely recover if iptables rules are accidentally flushed
on a ufw-managed host.

## What Happened
1. Attempted to rate-limit ICMP on a ufw-managed host using
   `iptables -A INPUT ...` (append). The rule had zero effect --
   pings succeeded 100% of the time, rule showed 0 packet hits.
2. Investigated with `iptables -L INPUT -v -n`: ufw's own chains
   (ufw-before-input, etc.) sit ahead of anything appended to the end
   of INPUT. ufw's before.rules file contains an unconditional
   `-A ufw-before-input -p icmp --icmp-type echo-request -j ACCEPT`,
   which matched and accepted traffic before the custom rule was ever
   evaluated.
3. Attempted to clean up with `sudo iptables -F INPUT` -- this flushed
   ALL rules in INPUT, including ufw's own chains, not just the custom
   test rules. Result: INPUT chain empty, default policy DROP, meaning
   all incoming traffic (including SSH, HTTP) was being silently
   dropped. Confirmed via `iptables -L INPUT -v -n` showing zero rules
   and a rising dropped-packet counter.
4. Recovered with `sudo ufw reload` -- ufw rebuilt its entire chain
   structure from its own saved config files (/etc/ufw/), fully
   restoring the original rule set with no data loss.
5. Corrected the original approach: used `iptables -I INPUT 1 ...`
   (insert at position 1) instead of `-A` (append), placing the
   rate-limit rules ahead of ufw's own chains. Verified with
   `iptables -L INPUT -v -n --line-numbers` that the custom rules sat
   at positions 1-2, genuinely ahead of ufw-before-input at position 3.
   Retested: rate limit now worked as intended.

## Evidence
- Before fix: iptables -L INPUT showed custom rule at 0 pkts/0 bytes
  after real traffic was sent -- proof the rule was never reached.
- After flush: iptables -L INPUT showed policy DROP, 335 packets/
  31521 bytes dropped -- proof of active, unintended traffic loss.
- After ufw reload: full chain structure and ufw status verbose
  output identical to the pre-incident baseline -- proof of clean,
  complete recovery.
- After correct insertion: iptables -L INPUT --line-numbers showed
  custom rules at positions 1-2, ufw-before-input at position 3 --
  proof of correct ordering this time.

## Real-World Relevance
- iptables chains are evaluated top to bottom; a rule's PRESENCE does
  not guarantee it runs before other rules that already match the same
  traffic. Higher-level tools (ufw, firewalld) manage their own chains
  and can silently override rules added elsewhere in the same base
  chain if those rules are appended rather than inserted ahead of them.
- `iptables -F <chain>` is indiscriminate -- it removes every rule in
  that chain regardless of which tool or process added it. On any
  ufw/firewalld-managed host, this is a genuinely dangerous command
  to run casually.
- `ufw reload` (or `ufw disable && ufw enable`) is a safe, complete
  recovery path after an accidental iptables-level change to a
  ufw-managed chain, since ufw's rules live in its own config files,
  not solely in the live kernel rule table.
