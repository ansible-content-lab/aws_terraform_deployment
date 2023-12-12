variable "deployment_id" {}
variable "instance_name_suffix" {}
variable "vm_name_prefix" {}
variable "latest_al2_linux_ami" {}

variable "app_tag" {
  description = "Tag value for AAP component"
  validation {
    condition = var.app_tag == "controller" || var.app_tag == "hub"
    error_message = "Invalid app_tag. Valid values are 'controller' or 'hub'."
  }
  type = string
  default = "controller"
}

resource "aws_instance" "aapvm" {
  ami = var.latest_al2_linux_ami
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
