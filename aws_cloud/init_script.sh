#!/bin/bash
set -ex
sudo yum update -y
sudo yum install git -y

sudo swapoff -a
sudo sed -i '/swap/d' /etc/fstab
curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION="v1.28.6+k3s1" sh -

# Wait until k3s service is active
echo "Waiting for k3s service to be active..."
for i in {1..30}; do
  if sudo systemctl is-active --quiet k3s; then
    echo "k3s is active!"
    break
  else
    echo "k3s not active yet. Sleeping 5s..."
    sleep 5
  fi
done

# Extra check: fail if k3s is still not active
if ! sudo systemctl is-active --quiet k3s; then
  echo "ERROR: k3s did not start within expected time"
  exit 1
fi