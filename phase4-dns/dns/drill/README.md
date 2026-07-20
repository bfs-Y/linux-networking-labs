# Recall Practice — Phase 4: DNS / /etc/hosts Override Mechanism

TOPIC: Local Resolution Override and Backup Integrity
DATE STARTED: 2026-07-14
TARGET: answer all drills without checking reference.

DRILL 1 — A domain resolves to the wrong IP even though DNS itself
is confirmed healthy (dig against the real nameserver returns the
correct answer). What local file, checked before DNS is ever
queried, commonly explains this?
YOUR ANSWER:
>
REFERENCE:
/etc/hosts -- check with: getent hosts <domain>
nsswitch.conf's default resolution order checks hosts file entries
before DNS.

DRILL 2 — A "restore from backup" fix script reports success, but
the bad state is still present afterward. What's the first thing to
verify before trusting any restore script's backup source?
YOUR ANSWER:
>
REFERENCE:
Whether the backup itself was clean at the moment it was taken --
grep the backup file directly for the known-bad entry before
restoring from it. A restore is only as good as what was backed up.

SPEED ROUND — cover reference column, write the command aloud/on paper:

Check what a hostname actually resolves to locally    -> getent hosts <domain>
Verify a target string isn't already in /etc/hosts     -> grep -qE "[[:space:]]<domain>([[:space:]]|$)" /etc/hosts
Find the most recent timestamped backup file            -> ls -t /etc/hosts.bak.* | head -n1

WEAK SPOT LOG:
Date       | What I got wrong | Fixed?
