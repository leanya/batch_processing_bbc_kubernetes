terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 5.80.0"
    }
  }
  required_version = "~> 1.10.0"
}

provider "aws" {
  region     = "ap-southeast-1"
}

data "aws_ami" "ami_amazon" {
  most_recent = true
  owners = ["amazon"]
  filter{
      name   = "name"
      values = ["al2023-ami-2023*kernel-6.1-x86_64"]
  }
}

resource "aws_instance" "myec2_tf" {
  ami = data.aws_ami.ami_amazon.id
  instance_type = var.instance_type
  key_name = var.key_name
  vpc_security_group_ids = [var.vpc_security_group_id]

  user_data = file("./init_script.sh")

  tags = {
    Name = "terraform_ec2"
  }

  # provisioner to install and wait for k3s in the init-script
  provisioner "remote-exec" {
    inline = [
      "sudo swapoff -a",
      "sudo sed -i '/swap/d' /etc/fstab",
      "PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)",
      "sudo curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION='v1.28.6+k3s1' INSTALL_K3S_EXEC='--disable=traefik --tls-san $PUBLIC_IP' sh -",
      "echo PUBLIC_IP=$PUBLIC_IP",
      "sudo chmod 644 /etc/rancher/k3s/k3s.yaml",
      "sudo chown ec2-user:ec2-user /etc/rancher/k3s/k3s.yaml",
      "sudo touch /var/run/k3s-ready",
      "echo 'Waiting for k3s to be ready...'",
      "while [ ! -f /var/run/k3s-ready ]; do sleep 5; done",
      "echo 'k3s is ready, init script complete.'"
    ]

    connection {
      type        = "ssh"
      host        = self.public_ip
      user        = "ec2-user"
      private_key = file("~/.ssh/id_rsa") 
    }
  }
}

output "instance_public_ip" {

  value = aws_instance.myec2_tf.public_ip
  description = "Public IP address of the EC2 instance"
}