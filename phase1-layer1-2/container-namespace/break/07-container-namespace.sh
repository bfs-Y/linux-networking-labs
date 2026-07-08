#!/bin/bash
# Break 07: Start a container to demonstrate network namespace isolation
# Effect: creates a process with its own private network stack, bridged via docker0
# Recovery: fix/07-container-cleanup.sh

echo "[BREAK] Starting test container..."
sudo docker run -d --name test-container nginx
echo "[VERIFY] Container running:"
sudo docker ps | grep test-container
echo "[VERIFY] Container's private network namespace:"
sudo docker inspect test-container | grep -A 5 '"IPAddress"'
echo "[VERIFY] Host's docker0 bridge state:"
ip a show docker0
