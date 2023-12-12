resource "aws_instance" "aapvm" {
  ami = var.latest_rhel9_ami
  instance_type = var.instance_type
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
