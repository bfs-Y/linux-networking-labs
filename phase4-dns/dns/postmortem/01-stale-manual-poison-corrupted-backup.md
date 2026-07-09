## Incident
Fix script (01-hosts-restore.sh) reported success but did not actually clear
the DNS poisoning — resolution still showed the wrong IP after "restore."

## Timeline
1. Hours earlier, manually ran a poison command directly in the terminal to
   test the /etc/hosts override concept, before any script existed.
2. Never cleaned up that manual entry — it stayed in /etc/hosts.
3. Later, wrote and ran break/01-hosts-override.sh, which correctly backed up
   /etc/hosts — but the file was ALREADY poisoned at backup time.
4. Ran fix/01-hosts-restore.sh — it correctly restored from the backup, but
   the backup itself contained the bad entry, so "restore" returned to a
   still-broken state.

## Root Cause
A backup is only as good as the state it captures. The backup step never
verified the file was clean before backing it up, so a stale manual test
artifact got permanently baked into the "known good" backup.

## What Fixed It
Manually removed the stale entry with sed, since no earlier clean backup
existed to restore from.

## What I Missed
Ran a manual test directly against a live system file without a cleanup step
or verification that the environment was reset to baseline before starting
the scripted break/fix cycle.

## Prevention
Break scripts that create a "backup" for later restore should verify the
target file's state is sane BEFORE backing it up — e.g., grep for the target
domain first and warn/abort if it's unexpectedly already present, rather than
silently backing up a corrupted starting state.
