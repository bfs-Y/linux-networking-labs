# Recall Practice — ufw/iptables Rule Precedence and Safe Recovery

TOPIC: Firewall Rule Ordering and Flush Recovery
DATE STARTED: 2026-08-22
TARGET: answer without checking reference — write the actual command.

DRILL 1 — You appended an iptables rule to INPUT on a ufw-managed host,
but it has zero effect -- matching traffic still gets through. Write
the command to see WHERE in the chain your rule actually sits relative
to ufw's own chains.
YOUR ANSWER:
>
REFERENCE: sudo iptables -L INPUT -v -n --line-numbers

DRILL 2 — You need a custom iptables rule to be evaluated BEFORE ufw's
own chains, not after. Write the command to insert it at the very top
of INPUT (position 1).
YOUR ANSWER:
>
REFERENCE: sudo iptables -I INPUT 1 <rule-spec>

DRILL 3 — You accidentally ran `sudo iptables -F INPUT` on a ufw-managed
host, and now SSH/HTTP access is failing. What is the safe, correct
recovery command -- NOT manually re-typing every rule from memory?
YOUR ANSWER:
>
REFERENCE: sudo ufw reload
(rebuilds the full chain structure from ufw's own saved config in /etc/ufw/)

DRILL 4 — You want to remove ONE specific rule you added, without
risking any of ufw's own rules. What command removes exactly that one
rule, and what command should you NEVER use for this purpose on a
ufw-managed chain?
YOUR ANSWER:
>
REFERENCE:
Safe: sudo iptables -D INPUT <exact-rule-spec>
Never: sudo iptables -F INPUT (flushes everything in the chain,
including rules you didn't add)

DRILL 5 — After a suspected accidental firewall change, what single
command confirms whether the default DROP policy is actively dropping
real traffic right now?
YOUR ANSWER:
>
REFERENCE: sudo iptables -L INPUT -v -n
(check the policy line for a nonzero, rising dropped-packet counter)

SPEED ROUND — cover reference column, write the command aloud/on paper:

See rule order with line numbers               -> iptables -L INPUT -v -n --line-numbers
Insert a rule at the very top of a chain        -> iptables -I INPUT 1 <rule-spec>
Safely recover a ufw-managed chain after a flush -> ufw reload
Remove one specific rule without a full flush    -> iptables -D INPUT <exact-rule-spec>
Check for active, rising drop counts             -> iptables -L INPUT -v -n

WEAK SPOT LOG:
Date       | What I got wrong                                          | Fixed?
2026-08-22 | Ran iptables -F INPUT to "clean up," flushed ufw's rules   | Yes -- ufw reload
2026-08-22 | Used -A (append) instead of -I (insert), rule never fired  | Yes -- verified with --line-numbers
