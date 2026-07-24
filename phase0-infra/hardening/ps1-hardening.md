# PS1 Hardening

## Overview
While working through the networking labs, I accidentally ran commands on
the hypervisor instead of the Ubuntu training VM. At the time, I believed
I was testing connectivity between the training VM and another host, but
I was actually testing connectivity from the hypervisor. The issue was
identified by comparing the expected ICMP source address against the
actual source address captured in tcpdump.

To reduce the chance of repeating this mistake, each lab machine has a
unique, persistent shell prompt showing hostname and a distinct color.

This is the second iteration of this fix. The first iteration (colors:
bright red/yellow/magenta) was implemented but the underlying mistake
recurred multiple times in a later session anyway, since the earlier fix
alone did not prevent misreading which terminal was active. Colors were
changed to a second scheme (red/green/blue) during that session, which
briefly left duplicate PS1/PROMPT assignments in each config file
(old line plus new line, both present) before being cleaned up.

## Host Configuration
| Host | Shell | Config File | Prompt Color |
|------|-------|-------------|--------------|
| Hypervisor (ibnb-Latitude-E7240) | zsh | ~/.zshrc | Red |
| training-vm (Ubuntu 24.04) | bash | ~/.bashrc (line 119) | Green |
| centos9 (CentOS Stream 9) | bash | ~/.bashrc (line 30) | Blue |

## Prompt Configuration

### Hypervisor (ibnb-Latitude-E7240)
    PROMPT="%F{red}[HYPERVISOR|ibnb-Latitude-E7240]%f %n@%m:%~$ "

### training-vm (Ubuntu 24.04)
    export PS1="\[\e[32m\][training-vm|Ubuntu24.04]\[\e[0m\] \u@\h:\w\$ "

### centos9 (CentOS Stream 9)
    export PS1="\[\e[34m\][centos9|CentOS9]\[\e[0m\] \u@\h:\w\$ "

## Verification
Verified with:
    grep -n PS1 ~/.bashrc        # training-vm, centos9
    grep -n -E 'PS1|PROMPT' ~/.zshrc   # hypervisor
Confirmed exactly one active PS1/PROMPT assignment per host, no
duplicate/conflicting lines, matching the live prompt shown in a
freshly opened terminal on each machine.

## Known Inconsistency
training-vm's ~/.bashrc retains three earlier conditional PS1 lines
(60, 62, 69) from the Ubuntu default config, inside terminal-capability
if-branches. The line-119 assignment executes last and wins in this
environment; left in place rather than removed to avoid touching
untested conditional logic.

## Why This Matters
A shell prompt that doesn't identify its host is an unverified
assumption every time a command is typed. This mistake cost real time
diagnosing faults that never existed, more than once, including after
an earlier version of this same fix was already in place - the fix
itself is necessary but not sufficient; it still requires actually
reading the prompt before trusting command output.
