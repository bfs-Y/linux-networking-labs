
Date: 2026-09-06

Lab: Phase 5 (Observability) - Nmap exposure validation surfaced a real

firewall-vs-service-state discrepancy on centos9.

Symptom (verbatim command and output):

Full all-port scan against centos9:

$ sudo nmap -p- 192.168.122.207

  PORT     STATE  SERVICE

  22/tcp   open   ssh

  9090/tcp closed zeus-admin

Port 9090 showed CLOSED, despite firewalld explicitly listing

`cockpit` as an allowed service on this host (confirmed separately

via `sudo firewall-cmd --list-all`, `services: cockpit dhcpv6-client

ssh`). A firewall rule existing for a port with nothing reachable

there is a real discrepancy worth investigating, not assumed benign.

Root cause:

$ sudo systemctl status cockpit.socket

    Loaded: loaded (/usr/lib/systemd/system/cockpit.socket; disabled; ...)

    Active: inactive (dead)

    Listen: [::]:9090 (Stream)

cockpit.socket (the systemd socket unit that activates Cockpit

on-demand) is disabled and inactive. The firewall rule permitting

traffic to port 9090 is correctly configured, but the service it's

meant to protect access to was never actually started/enabled. Two

independent layers - firewall rule and service state - both need to

be correct for a service to be genuinely reachable, and only one was.

Evidence:

- `-sV` version detection correctly identified the real service on

  22/tcp (OpenSSH 9.9, protocol 2.0) by actually probing it, but could

  not identify anything on 9090 - because nothing was listening there

  to probe in the first place, confirming "closed" was accurate, not

  a scan artifact.

- Nmap's default service-name guess for 9090 ("zeus-admin") was a

  stale port-database lookup, unrelated to what's actually configured

  on this host (Cockpit) - a separate, secondary finding: don't trust

  Nmap's default label as identification, verify independently.

What changed vs what stayed the same:

Nothing was changed on centos9 as part of this investigation - this

was a read-only exposure validation exercise. cockpit.socket remains

disabled/inactive; no action was taken to enable it, since there was

no stated need for Cockpit's web UI on this training host. Documented

as a real, understood configuration state, not left as an unexplained

"closed" result.

Fix applied:

N/A - no fix needed or applied. This is the inverse case of the

loadbalancer topic's finding (there: service ran, firewall blocked

it; here: firewall allows it, service was never started) - both are

legitimate configuration states once understood, and in this case the

"closed" state is arguably the SAFER one: less exposed attack surface

than if Cockpit were actually running and reachable. If Cockpit

access were later needed, the fix would be

`sudo systemctl enable --now cockpit.socket`.

Automated or permanent version of the fix:

N/A - no active fault to automate a fix for. If this pattern recurs

(a firewall-allowed port showing consistently closed) as part of

routine exposure validation, the check itself

(`nmap -p- <host>` + `systemctl status <service>` for any

unexpectedly-closed-but-allowed port) is the repeatable verification

step - already demonstrated live and documented in lab-notes/02.

Detection gap:

A firewall configuration review alone (`firewall-cmd --list-all`)

would have reported this port as "allowed" with no indication that

nothing was actually listening - exactly the gap exposure validation

exists to close. Reading firewall config as if it described actual

current exposure, without a live scan to confirm, would have produced

a false sense of what's genuinely reachable on this host.

