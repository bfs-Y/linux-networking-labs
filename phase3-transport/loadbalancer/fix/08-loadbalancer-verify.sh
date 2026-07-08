#!/bin/bash
# Fix 08: Diagnose a load balancer returning 502, and verify correct distribution
# Pairs with: break/08-loadbalancer-setup.sh
# Common real failure: backends die independently of the proxy. 502 = proxy alive, backend dead.

echo "[DIAGNOSE] Checking backend availability first (502 always means check the backend):"
sudo ss -tulnp | grep -E "8081|8082" || echo "No backends listening — this is why you'd see 502"

echo "[DIAGNOSE] Checking nginx itself is actually running:"
sudo systemctl status nginx --no-pager | grep Active

echo "[TEST] Sending 5 requests through the load balancer:"
for i in 1 2 3 4 5; do curl -s http://localhost:8090; done

echo ""
echo "[VERIFY] If you saw a mix of 'Server 1' and 'Server 2' above, round-robin is working."
echo "If you saw only one server repeatedly, or 502s, check: are both backends alive? Is nginx running?"
