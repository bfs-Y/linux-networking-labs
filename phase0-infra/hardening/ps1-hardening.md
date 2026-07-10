# PS1 Hardening

## Overview
While working through the networking labs, I accidentally ran commands on the hypervisor instead of the Ubuntu training VM. At the time, I believed I was testing connectivity between the training VM and another host, but I was actually testing connectivity from the hypervisor. The issue was identified by comparing the expected ICMP source address against the actual source address captured in tcpdump.

To reduce the chance of repeating this mistake, each lab machine now has a unique, persistent shell prompt showing hostname and a distinct color.

## Host Configuration

| Host | Shell | Config File | Prompt Color |
|------|-------|-------------|--------------|
| Hypervisor (Ubuntu) | zsh | ~/.zshrc | Bright Red |
| Ubuntu Training VM | bash | ~/.bashrc (line 119) | Bright Yellow |
| CentOS 9 | bash | ~/.bashrc (line 30) | Bright Magenta |

## Prompt Configuration

### Hypervisor
export PS1='%F{red}[%n@%m %1~]$ %f'

### Ubuntu Training VM
PS1='\[\e[1;33m\][\u@\h \W]\$ '

### CentOS 9
export PS1='\[\e[1;35m\][\u@\h \W]\$ \[\e[0m\]'

## Verification
Verified by opening a genuinely new terminal session per host (not re-sourcing an existing shell) and confirming:
- grep -n PS1 <config file> matches the running $PS1 exactly
- hostname is visible in the prompt
- color is unique per host

## Known Inconsistency
training-vm's ~/.bashrc retains three earlier conditional PS1 lines (60, 62, 69) from the Ubuntu default config, inside terminal-capability if-branches. The line-119 assignment executes last and wins in this environment; left in place rather than removed to avoid touching untested conditional logic.

## Why This Matters
A shell prompt that doesn't identify its host is an unverified assumption every time a command is typed. This mistake cost real time diagnosing a network fault that never existed. The fix makes execution context visible without requiring a manual check.
