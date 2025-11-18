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
      "echo 'Waiting for k3s to be ready...'",
      "while ! sudo k3s kubectl get nodes >/dev/null 2>&1; do sleep 5; done",
      "echo 'k3s is ready, init script complete.'",
      # "managing K3s via the config file
      "sudo mkdir -p /etc/rancher/k3s",
      "sudo sh -c 'PUBLIC_IP=${self.public_ip}; printf \"tls-san:\\n  - %s\\n\" \"$PUBLIC_IP\" > /etc/rancher/k3s/config.yaml'",
      # Restart k3s
      "sudo systemctl restart k3s",
      "sudo systemctl status k3s --no-pager",
      "while ! sudo k3s kubectl get nodes >/dev/null 2>&1; do sleep 5; done",
      "echo 'k3s is ready, tls-san is updated with ec2 public ip.'"
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