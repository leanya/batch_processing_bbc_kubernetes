#!/bin/bash
set -ex

sudo yum update -y
sudo yum install git -y

sudo swapoff -a
sudo sed -i '/swap/d' /etc/fstab
# curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION="v1.28.6+k3s1" sh -

# public_ip = curl -v http://169.254.169.254/latest/meta-data/public-ipv4

for i in {1..30}; do
  public_ip=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
  if [[ -n "$public_ip" ]]; then
    break
  fi
  sleep 1
done

curl -sfL https://get.k3s.io | \
  INSTALL_K3S_VERSION="v1.28.6+k3s1" \
  INSTALL_K3S_EXEC="--disable=traefik --tls-san ${public_ip}" \
  sh -

# Wait until k3s service is active
# echo "Waiting for k3s service to be active..."
# for i in {1..30}; do
#   if sudo systemctl is-active --quiet k3s; then
#     echo "k3s is active!"
#     break
#   else
#     echo "k3s not active yet. Sleeping 5s..."
#     sleep 5
#   fi
# done


# update kubeconfig permissions
sudo chmod 644 /etc/rancher/k3s/k3s.yaml
sudo chown ec2-user:ec2-user /etc/rancher/k3s/k3s.yaml

touch /var/run/k3s-ready