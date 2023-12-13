output "instance_id" {
  description = "Instance ID"
  value = aws_instance.aapvm.id
}

output "vm_public_ip" {
  description = "Public IP address assigned to the instance"
  value = aws_instance.aapvm.public_ip
}

output "vm_private_ip" {
  description = "Private IP address assigned to the instance"
  value = aws_instance.aapvm.private_ip
}
