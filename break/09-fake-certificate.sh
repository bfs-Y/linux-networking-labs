#!/bin/bash
# Break 09: Generate a self-signed certificate impersonating a real domain
# Effect: simulates what an attacker would have to present without a real CA backing them
# Recovery: fix/09-certificate-inspection.sh (detection, not "fixing" someone else's fake cert)

FAKE_DOMAIN="fakebank.com"

echo "[BREAK] Generating a self-signed certificate claiming to be $FAKE_DOMAIN..."
openssl req -x509 -newkey rsa:2048 -keyout ~/fake-key.pem -out ~/fake-cert.pem -days 365 -nodes -subj "/CN=$FAKE_DOMAIN" 2>/dev/null

echo "[VERIFY] Read what this certificate actually claims:"
openssl x509 -in ~/fake-cert.pem -noout -subject -issuer

echo ""
echo "[THE TELL] subject and issuer are IDENTICAL — this entity is vouching for itself."
echo "A real certificate has a DIFFERENT issuer (a trusted Certificate Authority)."
