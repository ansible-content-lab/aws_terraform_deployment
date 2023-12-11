output "infrastructure_controller_rds_hostname" {
  description = "RDS instance hostname"
  value = aws_db_instance.controller.address
}

output "infrastructure_controller_rds_port" {
  description = "RDS instance port"
  value = aws_db_instance.controller.port
}
