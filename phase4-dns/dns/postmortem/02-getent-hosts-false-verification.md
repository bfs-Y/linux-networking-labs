## Incident
Both break/01-hosts-override.sh and fix/01-hosts-restore.sh used
`getent hosts $TARGET_DOMAIN` to prove /etc/hosts poisoning/restoration
worked. Both scripts printed successful [PROOF] messages that did not
match the actual state of /etc/hosts at the time.

## Evidence
- /etc/hosts confirmed (via grep) to contain "192.168.100.100 example.com"
- getent hosts example.com returned real DNS IPv6 addresses, not the
  hosts-file entry
- getent -s files hosts example.com (forced files-only) correctly
  returned 192.168.100.100
- getent ahosts example.com correctly returned 192.168.100.100
- /etc/host.conf's "order hosts,bind" ruled out as cause (legacy,
  inert on modern glibc, per its own comment)

## Root Cause
Not fully isolated to a single mechanism. Narrowed to: plain `getent
hosts` (glibc's combined address-family lookup) resolves differently
than `getent ahosts` or `getent -s files hosts` on this system, despite
nsswitch.conf listing "files" before "dns". Likely interaction with
systemd-resolved's NSS integration, not confirmed to exact mechanism.

## What Fixed It
Both scripts changed to use `getent ahosts` instead of `getent hosts`
for verification - confirmed to correctly reflect /etc/hosts content
in testing.

## Prevention
Any script using getent to verify /etc/hosts state should use `getent
ahosts` (or `getent -s files hosts` if only checking the files source
specifically), never plain `getent hosts`, on systems running
systemd-resolved.

## Open item
Exact mechanism for why plain `getent hosts` diverges from `ahosts`
not fully diagnosed - deferred, not blocking, since the practical fix
(use ahosts) is confirmed working.
