# Lab Notes: /etc/hosts Override and Backup Integrity
Topic: Local resolution override mechanism, backup integrity, verification pitfalls

--- THE CORE MECHANISM ---
/etc/hosts is checked before DNS per nsswitch.conf's default order
(files before dns). A single line in /etc/hosts silently overrides
DNS for that exact hostname - no error, no warning, just a different
answer than the real internet would give. This is legitimate
functionality (used for local overrides, testing, blocking) but
becomes a real incident when the override is unintentional or
forgotten.

--- BACKUP INTEGRITY: A BACKUP IS ONLY AS GOOD AS WHAT IT CAPTURED ---
Real incident this phase (postmortem/01): a manual test poisoned
/etc/hosts hours before any script existed. That stale entry was
never cleaned up. When break/01-hosts-override.sh later ran, it
backed up /etc/hosts BEFORE checking whether the file was already
poisoned - so the "known good" backup actually contained the bad
entry. The subsequent "restore" correctly restored the backup, but
the backup itself was corrupted, so the restore returned to a
still-broken state.
Fix applied: break script now greps for the target domain and ABORTS
before backing up if it's already present, rather than silently
preserving a bad starting state.

--- getent hosts IS NOT RELIABLE FOR VERIFYING /etc/hosts CONTENT ---
Real incident this phase (postmortem/02): both break and fix scripts
used `getent hosts $DOMAIN` to prove their work. Both printed
successful [PROOF] messages that did not match the actual file
content - confirmed via direct grep of /etc/hosts. `getent hosts`
(plain form) diverged from what /etc/hosts actually contained;
`getent ahosts` and `getent -s files hosts` correctly reflected it.
Root mechanism not fully isolated (see postmortem/02's open item),
but the practical fix is clear: use `getent ahosts`, never plain
`getent hosts`, to verify /etc/hosts state on this system.

--- THE GENERAL LESSON, TWICE OVER ---
Both incidents in this topic share one root cause: trusting a
command's output as proof of underlying state, without directly
checking that state. A backup command succeeding doesn't mean the
captured state was good. A getent command returning a "correct-
looking" answer doesn't mean it came from the source you assumed.
Direct evidence (grep the actual file) beats an indirect proxy
(a resolution tool's answer) every time there's any doubt.

--- PRODUCTION RELEVANCE ---
Any script that backs up a file before modifying it should verify
the file's starting state is sane BEFORE backing it up - a "restore"
mechanism is worthless if what it restores from was already broken.
Any script that verifies DNS/hosts behavior should confirm which
tool it's actually testing (getent hosts vs ahosts vs a direct file
read) rather than assuming two similarly-named commands behave
identically.
