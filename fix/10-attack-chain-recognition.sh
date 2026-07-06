#!/bin/bash
# Fix 10: This isn't a destructive break to "fix" — it's recognition.
# You cannot fix someone else's Evil Twin hotspot or DNS spoofing attempt.
# The actual defense is recognizing the warning signs and refusing to proceed.
# Pairs with: break/10-cleartext-capture.sh

echo "[RECOGNITION CHECKLIST] Signs you may be on a malicious/Evil Twin network:"
echo "1. A certificate warning appears where it normally wouldn't — DO NOT click through"
echo "2. A site you know is normally HTTPS suddenly loads as plain HTTP"
echo "3. A familiar WiFi name appears in an unexpected location (different city/venue)"
echo "4. Unexpected captive-portal-style login pages on sites that shouldn't show one"
echo ""
echo "[VERIFY A CONNECTION'S CERTIFICATE BEFORE TRUSTING IT]"
echo "echo | openssl s_client -connect <domain>:443 -servername <domain> 2>/dev/null | openssl x509 -noout -subject -issuer -dates"
echo ""
echo "[VERIFY DNS IS RESOLVING SENSIBLY]"
echo "dig <domain>   # does the returned IP look legitimate, or wildly unexpected?"
echo ""
echo "[THE ACTUAL DEFENSE]"
echo "TLS catches fake certificates (proven in Topic 9). It CANNOT catch SSL stripping,"
echo "because stripping prevents TLS from ever starting. The real defense against"
echo "stripping is: browsers/sites using HSTS (forcing HTTPS-only, never allowing a"
echo "plain HTTP fallback) and YOU noticing when an expected HTTPS site loads as HTTP."
