provider "aws" {
  region = var.aws_region
}

variable "dep_id" {}

variable "app_tag" {
  description = "Tag value for AAP component"
  validation {
    condition     = var.app_tag == "controller" || var.app_tag == "hub"
    error_message = "Invalid app_tag. Valid values are 'controller' or 'hub'."
  }
  type    = string
  default = "controller"
}

variable "aws_region" {
  description = "Region where the EC2 instance will be launched"
  type = string
  default = "us-east-1"
}

variable "vm_name_prefix" {
  description = "Name of ec2 instance"
  type    = string
  default = "<vm_name>"
}

resource "random_string" "instance_name_suffix" {
  length  = 8
  special = false
  upper   = false
  numeric  = false
}

resource "aws_instance" "aapvm" {
  ami           = "<image_id>"
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
    Name = "aap-infrastructure-${var.dep_id}-vm-${var.vm_name_prefix}${random_string.instance_name_suffix.result}"
    app = var.app_tag
  }
}
