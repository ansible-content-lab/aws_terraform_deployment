provider "aws" {
  region = var.aws_region
}

variable "deployment_id" {}
variable "instance_name_suffix" {}
variable "vm_name_prefix" {}

variable "app_tag" {
  description = "Tag value for AAP component"
  validation {
    condition = var.app_tag == "controller" || var.app_tag == "hub"
    error_message = "Invalid app_tag. Valid values are 'controller' or 'hub'."
  }
  type = string
  default = "controller"
}

variable "aws_region" {
  description = "Region where the EC2 instance will be launched"
  type = string
  default = "us-east-1"
}

resource "aws_instance" "aapvm" {
  ami = "<image_id>"
  instance_type = "m5a.xlarge"
  key_name = "<key_name>"

  associate_public_ip_address = true
  subnet_id = "<subnet_id>"
  vpc_security_group_ids = ["<security_group_id>"]

  root_block_device {
    volume_type = "io1"
    volume_size = 100
    iops = 1500
    delete_on_termination = true
  }

  tags = {
    Name = "aap-infrastructure-${var.deployment_id}-vm-${var.vm_name_prefix}${var.instance_name_suffix}"
    app = var.app_tag
  }
}
