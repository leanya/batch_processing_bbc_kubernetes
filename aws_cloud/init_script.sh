#!/bin/bash
set -ex
sudo yum update -y
sudo yum install curl wget git -y

sudo swapoff -a
sudo sed -i '/swap/d' /etc/fstab
curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION="v1.28.6+k3s1" sh -