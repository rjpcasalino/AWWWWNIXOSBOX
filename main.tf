terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}

# ==============================================================================
# 1. Fetch Latest Official NixOS ARM64 AMI Dynamically
# ==============================================================================
data "aws_ami" "nixos_arm64" {
  most_recent = true
  owners      = ["427812963091"] # Official NixOS AWS Account

  filter {
    name   = "name"
    values = ["nixos/2*"]
  }

  filter {
    name   = "architecture"
    values = ["arm64"]
  }
}

# ==============================================================================
# 2. Provision EC2 Instance with IPv6 & Remote `nixos-rebuild`
# ==============================================================================
resource "aws_instance" "nixos_box" {
  ami                    = data.aws_ami.nixos_arm64.id
  instance_type          = "t4g.micro"
  key_name               = "NixOSBox"
  subnet_id              = "subnet-027c24f2ad3579f0d"
  vpc_security_group_ids = ["sg-036492da66e29f958"]

  # Enable IPv6 address allocation
  ipv6_address_count          = 1
  associate_public_ip_address = false

  ebs_optimized = true

  root_block_device {
    delete_on_termination = true
    volume_type           = "gp3"
    volume_size           = 8
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
    instance_metadata_tags      = "disabled"
  }

  provisioner "local-exec" {
    command = <<-EOT
      IPV6_ADDR="${self.ipv6_addresses[0]}"
      KEY_PATH="${pathexpand("~/.ssh/NixOSBox.pem")}"
      SSH_CMD="ssh -6 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i $KEY_PATH"

      echo "Waiting for SSH authorization on $IPV6_ADDR..."
      until $SSH_CMD root@$IPV6_ADDR true 2>/dev/null; do
        sleep 5
      done

      echo "SSH authorized! Provisioning 2GB temporary swap on target..."
      $SSH_CMD root@$IPV6_ADDR "
        if [ ! -f /swapfile ]; then
          fallocate -l 2G /swapfile && chmod 600 /swapfile && mkswap /swapfile && swapon /swapfile
        fi
      "

      echo "Uploading configuration over SSH stream..."
      $SSH_CMD root@$IPV6_ADDR "mkdir -p /etc/nixos && cat > /etc/nixos/configuration.nix" < ./nixos/configuration.nix

      echo "Building and applying NixOS configuration on target..."
      # Restrict Nix to 1 job and 1 core to prevent RAM spikes
      $SSH_CMD root@$IPV6_ADDR "nixos-rebuild switch -I nixos-config=/etc/nixos/configuration.nix --option max-jobs 1 --option cores 1"
    EOT
  }

  tags = {
    Name = "NixOSBox"
  }
}

# ==============================================================================
# 3. Output Configuration
# ==============================================================================
output "web_app_url" {
  description = "Public IPv6 URL for the deployed NixOS app"
  value       = "http://[${aws_instance.nixos_box.ipv6_addresses[0]}]"
}

output "nixos_ipv6_address" {
  description = "IPv6 address assigned to the instance"
  value       = aws_instance.nixos_box.ipv6_addresses[0]
}
