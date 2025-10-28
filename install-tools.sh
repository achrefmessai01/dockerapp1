#!/bin/bash
set -e

apt-get update
apt-get install -y --no-install-recommends docker.io curl ca-certificates

STABLE=$(curl -L -s https://dl.k8s.io/release/stable.txt)
curl -LO "https://dl.k8s.io/release/${STABLE}/bin/linux/amd64/kubectl"
chmod +x kubectl
mv kubectl /usr/local/bin/

echo "Install script completed"
