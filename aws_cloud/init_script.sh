#!/bin/bash
set -ex

echo "$(date) - INIT SCRIPT START" | sudo tee /var/log/init_script.log

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


# update kubeconfig permissions
sudo chmod 644 /etc/rancher/k3s/k3s.yaml
sudo chown ec2-user:ec2-user /etc/rancher/k3s/k3s.yaml

echo "$(date) - INIT SCRIPT COMPLETE, k3s is ready" | sudo tee -a /var/log/init_script.log

touch /var/run/k3s-ready