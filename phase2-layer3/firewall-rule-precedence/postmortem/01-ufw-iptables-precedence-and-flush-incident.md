# Postmortem

Date: 2026-08-22

Lab: Phase 2 -- ufw/iptables Rule Precedence and Accidental Flush Recovery

## Symptom (verbatim command and output)

Command: iptables -L INPUT -v -n (after appending a custom ICMP rule)
Output showed the custom rule with 0 pkts/0 bytes despite real ping
traffic having been sent from another host -- the rule was never
matched at all.

Later, after `sudo iptables -F INPUT`:
Chain INPUT (policy DROP 335 packets, 31521 bytes)
(zero rules present)

## Root Cause

Two distinct root causes, one incident:

1. iptables rules appended with -A land at the END of a chain. On this
   ufw-managed host, ufw's own chains (ufw-before-input, containing an
   unconditional ICMP echo-request ACCEPT) are evaluated first. The
   appended custom rule was syntactically valid and present, but
   unreachable -- traffic was already accepted by ufw's rule before
   ever reaching it.

2. Attempting to "clean up" with `iptables -F INPUT` flushed the ENTIRE
   INPUT chain, including ufw's own rules, not just the custom test
   rule. With the chain empty and default policy DROP, all incoming
   traffic (SSH, HTTP, everything) was silently dropped.

## Evidence

- iptables -L INPUT -v -n --line-numbers (before flush): custom rule
  visible but showing 0 hits, positioned after ufw-before-input.
- iptables -L INPUT -v -n (after flush): policy DROP, 335 packets /
  31521 bytes already dropped -- direct proof of active traffic loss.
- iptables -L INPUT -v -n (after `ufw reload`): full chain structure
  restored, matching pre-incident state exactly.
- ufw status verbose (after reload): identical output to the baseline
  captured before the incident -- confirms complete, lossless recovery.

## What Changed vs What Stayed the Same

Changed: INPUT chain contents, twice -- once when the ineffective
custom rule was appended, once (destructively) when the chain was
flushed entirely.

Stayed the same: ufw's saved configuration files in /etc/ufw/ were
never touched -- this is what made full recovery possible via reload
rather than manual rule reconstruction.

## Fix Applied

sudo ufw reload -- rebuilt the entire INPUT chain structure from ufw's
own saved configuration, with zero manual rule re-entry required.

Corrected approach for the original goal: used `iptables -I INPUT 1`
(insert at top) instead of `-A` (append), placing custom rules ahead
of ufw's chains where they are actually evaluated.

## Automated or Permanent Version of the Fix

break/01-append-rule-ufw-overrides-it.sh and
fix/01-remove-appended-rule-safely.sh -- reproduce the ineffective-
append scenario and demonstrate the safe, targeted removal approach
(iptables -D on the specific rule) rather than a full chain flush.

## Detection Gap

A rule that is syntactically valid and visibly present in the chain
listing can still be completely ineffective if it sits after another
rule that already matches the same traffic. Always check rule ORDER
(iptables -L <chain> -v -n --line-numbers) and hit counters, not just
rule presence, when a firewall change appears to have no effect.

Separately: `iptables -F <chain>` should be treated as a high-risk
command on any host managed by a higher-level firewall tool (ufw,
firewalld) -- it does not distinguish between rules you added and
rules the management tool owns. Prefer targeted removal (`-D`) of a
specific rule, and know the tool-specific reload/recovery command
(`ufw reload`) before ever running a full chain flush.
