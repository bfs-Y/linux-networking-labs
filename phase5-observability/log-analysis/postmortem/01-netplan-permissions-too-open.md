
Date: 2026-09-06

Lab: Phase 5 (Observability) - NetworkManager log analysis surfaced a

real, previously-unnoticed security misconfiguration.

Symptom (verbatim command and output):

Ran `sudo journalctl -u NetworkManager -p warning --no-pager` as part

of a log-analysis exercise (unit scoping + priority filtering to cut

through routine info-level noise). Found a warning recurring at

nearly every single boot going back through the full journal history

(earliest entries in the retained log from Aug 5, matching the file's

modification date):

  generate[####]: Permissions for /etc/netplan/01-network-manager-all.yaml

  are too open. Netplan configuration should NOT be accessible by others.

This had never been noticed or investigated before this session,

despite appearing at nearly every boot for well over a year.

Root cause:

$ ls -l /etc/netplan/01-network-manager-all.yaml

  -rw-r--r-- 1 root root 104 Aug  5  2025 ...

File permissions were 644 (owner read/write, group and others

read-only) - readable by any local user on the system. Per Netplan's

own official security documentation, netplan YAML files can contain

credentials (VPN keys, WiFi passwords) and are required to be 600

(root read/write only) to prevent unprivileged local users from

reading them.

Evidence:

- Confirmed the warning was real and current (not stale), reproduced

  live via `sudo netplan generate`, which re-triggers the same

  permission check and prints the identical warning text.

- Cross-referenced against Netplan's official docs

  (netplan.readthedocs.io/en/stable/security/): "The recommended set

  of file permissions is to have all YAML files owned by and only

  readable/writable by the root user (chmod 600)."

- Cross-referenced against a real, independently-reported bug on the

  exact same filename (01-network-manager-all.yaml) confirming this

  is a known, common misconfiguration with the same documented fix.

Fix applied:

$ sudo chmod 600 /etc/netplan/01-network-manager-all.yaml

$ ls -l /etc/netplan/01-network-manager-all.yaml

  -rw------- 1 root root 104 Aug  5  2025 ...

Verification (not just trusted, re-run to confirm):

$ sudo netplan generate

  (no output - warning no longer fires)

Confirmed immediately, same session, not deferred to "next boot and

hope."

What changed vs what stayed the same:

Changed: file permissions on

/etc/netplan/01-network-manager-all.yaml, 644 -> 600.

Stayed the same: the file's actual network configuration content -

this was a permissions-only fix, no functional networking change,

confirmed by `netplan generate` completing without error (a broken

YAML syntax change would have surfaced a different error here).

Automated or permanent version of the fix:

NOT YET DONE. This was a manual one-time fix. Since this file is

managed by the `generate` step of Ubuntu's NetworkManager-renderer

netplan integration, it's worth checking whether a future netplan

regeneration (e.g. after a network config change via the GUI or

nmcli) could silently reset permissions back to 644 - not yet tested.

If so, a permanent fix might be a systemd path unit or a periodic

check, rather than a one-off chmod.

Detection gap:

This warning had been silently logging at INFO-adjacent visibility

(generate[PID]: message, not tagged with an obvious severity marker

in casual reading) at nearly every boot for over a year, and was

never noticed because nobody had ever filtered NetworkManager's log

stream by priority (-p warning) before this session. Lesson

generalized: a recurring warning that "has always been there" is not

evidence it's benign - it's evidence nobody has looked yet. Priority-

filtered log review (not just eyeballing raw output) is what

surfaced this.

