#!/bin/bash
# Fix 07: Stop and remove the test container cleanly
# Pairs with: break/07-container-namespace.sh

echo "[FIX] Stopping test-container..."
sudo docker stop test-container
echo "[FIX] Removing test-container..."
sudo docker rm test-container
echo "[VERIFY] Container no longer exists:"
sudo docker ps -a | grep test-container || echo "Confirmed clean — container removed"
echo "[VERIFY] docker0 returns to idle state with no containers attached:"
ip a show docker0
