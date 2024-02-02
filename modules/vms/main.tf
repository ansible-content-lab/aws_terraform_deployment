terraform {
  required_version = ">= 1.5.4"
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

resource "aws_instance" "aap_infrastructure_vm" {
  ami = var.instance_ami
  instance_type = var.instance_type
  key_name = var.key_pair_name

  associate_public_ip_address = true
  subnet_id = var.subnet_id
  vpc_security_group_ids = var.vpc_security_group_ids

  root_block_device {
    volume_type = var.infrastructure_volumes.volume_type
    volume_size = var.infrastructure_volumes.volume_size
    iops = var.infrastructure_volumes.iops
    delete_on_termination = var.infrastructure_volumes.delete_on_termination
  }
  tags = merge(
    {
      Name = "aap-infrastructure-${var.deployment_id}-vm-${var.vm_name_prefix}${var.instance_name_suffix}"
      app = var.app_tag
    },
    var.persistent_tags
  )
}

resource "terraform_data" "aap_infrastructure_sshkey" {
  depends_on = [ aws_instance.aap_infrastructure_vm ]
  count = var.app_tag == "controller" ? 1: 0
  connection {
      type = "ssh"
      user = var.infrastructure_admin_username
      host = aws_instance.aap_infrastructure_vm.public_ip
      private_key = file(var.infrastructure_ssh_private_key)
  }
  provisioner "file" {
    source = var.infrastructure_ssh_private_key
    destination = "/home/${var.infrastructure_admin_username}/.ssh/infrastructure_ssh_private_key.pem"
  }
  provisioner "remote-exec" {
    inline = [
      "chmod 0600 /home/${var.infrastructure_admin_username}/.ssh/infrastructure_ssh_private_key.pem",
    ]
  }
}

resource "terraform_data" "aap_subscription_manager" {
  depends_on = [ aws_instance.aap_infrastructure_vm ]
  connection {
    type = "ssh"
    user = var.infrastructure_admin_username
    host = aws_instance.aap_infrastructure_vm.public_ip
    private_key = file(var.infrastructure_ssh_private_key)
    timeout = "10m"
  }
  provisioner "remote-exec" {
    inline = [ 
      "sudo subscription-manager register --username ${var.aap_red_hat_username} --password ${var.aap_red_hat_password} --auto-attach",
      "sudo subscription-manager config --rhsm.manage_repos=1",
      "yes | sudo dnf upgrade"
      ]
  }
}
