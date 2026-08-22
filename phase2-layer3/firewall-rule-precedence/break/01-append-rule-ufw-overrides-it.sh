#!/usr/bin/env bash
# Break: append an ICMP-blocking rule to the END of INPUT on a
# ufw-managed host. Demonstrates that ufw's own chains (evaluated
# first) can silently override rules appended after them -- the
# appended rule has zero effect despite being present in the table.
set -euo pipefail

echo "Host check: $(hostname)"
echo "--- Appending ICMP DROP rule (will have no effect due to ufw precedence) ---"
sudo iptables -A INPUT -p icmp --icmp-type echo-request -j DROP

echo "--- Rule is present but sits AFTER ufw's own chains ---"
sudo iptables -L INPUT -v -n --line-numbers

echo ""
echo "Symptom: ping this host from another machine -- it will still"
echo "succeed 100% of the time despite the DROP rule being present,"
echo "because ufw-before-input's unconditional ICMP ACCEPT runs first."
echo ""
echo "DO NOT run 'iptables -F INPUT' to clean this up -- that flushes"
echo "ufw's own rules too. Use fix/01-remove-appended-rule-safely.sh"
