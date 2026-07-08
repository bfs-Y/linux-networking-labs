## Incident
Hardening script claimed static ARP entries resist poisoning; live test disproved this for local privileged replacement.

## Timeline
1. Wrote harden/01-arp-static-bindings.sh with PERMANENT ARP binding for gateway
2. Wrote NOTE claiming entry "will NOT be overwritten by a poisoned ARP reply"
3. Ran break/11-arp-poison-sim.sh (ip neigh replace, run locally as root) against the hardened entry
4. Poison succeeded — PERMANENT flag was overwritten, no resistance

## Root Cause
ip neigh replace has unconditional overwrite privilege regardless of NUD state (including PERMANENT) when run with CAP_NET_ADMIN — the permanent flag prevents normal aging/expiry, not deliberate privileged replacement.

## What Fixed It
Corrected the NOTE to accurately scope the defense: protects against remote/unsolicited ARP poisoning replies over the network, not local privileged overwrite.

## What I Missed
Assumed "permanent" meant "immutable" without checking kernel behavior. Didn't test the actual claim before writing it — wrote the NOTE aspirationally, not empirically.

## Prevention
Never write a defensive claim in a script comment without testing it against the exact attack it claims to stop, using the same privilege level a real attacker would have.
