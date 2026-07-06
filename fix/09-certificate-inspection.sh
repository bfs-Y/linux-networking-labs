#!/bin/bash
# Fix 09: Inspect and distinguish a real certificate from a self-signed one
# Pairs with: break/09-fake-certificate.sh
# This isn't "fixing" a fake cert (you can't fix someone else's impersonation) —
# it's the diagnostic skill: knowing how to verify a certificate's trust chain.

REAL_DOMAIN="${1:-example.com}"

echo "[INSPECT] Pulling a REAL certificate from $REAL_DOMAIN..."
echo | openssl s_client -connect "$REAL_DOMAIN:443" -servername "$REAL_DOMAIN" 2>/dev/null | openssl x509 -noout -subject -issuer -dates

echo ""
echo "[INSPECT] Comparing to the locally generated FAKE certificate (if it exists):"
if [ -f ~/fake-cert.pem ]; then
    openssl x509 -in ~/fake-cert.pem -noout -subject -issuer
else
    echo "(No fake cert found — run break/09-fake-certificate.sh first to generate one for comparison)"
fi

echo ""
echo "[VERDICT RULE]"
echo "subject == issuer            -> self-signed, no trusted third party, SUSPICIOUS"
echo "subject != issuer (real CA)  -> a trusted authority vouched for this identity"
echo "Always check notBefore/notAfter too — an expired real cert is also untrustworthy"
