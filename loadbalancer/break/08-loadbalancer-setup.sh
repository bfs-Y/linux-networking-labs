#!/bin/bash
# Break 08: Stand up two backend servers and an nginx load balancer in front of them
# Effect: demonstrates round-robin distribution across independent backends
# Recovery: fix/08-loadbalancer-verify.sh (verification, not removal — this isn't a "break" in the destructive sense)

mkdir -p ~/lb-test/server1 ~/lb-test/server2
echo "Response from Server 1" > ~/lb-test/server1/index.html
echo "Response from Server 2" > ~/lb-test/server2/index.html

echo "[SETUP] Starting backend 1 on 8081..."
cd ~/lb-test/server1 && python3 -m http.server 8081 &
disown

echo "[SETUP] Starting backend 2 on 8082..."
cd ~/lb-test/server2 && python3 -m http.server 8082 &
disown

sleep 1
echo "[VERIFY] Both backends listening:"
sudo ss -tulnp | grep -E "8081|8082"

sudo tee /etc/nginx/sites-available/loadbalancer.conf > /dev/null << 'NGINXEOF'
upstream backend_pool {
    server 127.0.0.1:8081;
    server 127.0.0.1:8082;
}

server {
    listen 8090;

    location / {
        proxy_pass http://backend_pool;
    }
}
NGINXEOF

sudo ln -sf /etc/nginx/sites-available/loadbalancer.conf /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx
