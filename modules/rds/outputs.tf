output "infrastructure_controller_rds_hostname" {
  description = "RDS instance hostname"
  value = aws_db_instance.controller.address
}
output "infrastructure_hub_rds_hostname" {
  description = "Hub RDS instance hostname"
  value = var.infrastructure_hub_count > 0 ? aws_db_instance.hub[0].address : ""
}
output "infrastructure_eda_rds_hostname" {
  description = "EDA RDS instance hostname"
  value = var.infrastructure_eda_count > 0 ? aws_db_instance.eda[0].address : ""
}

output "infrastructure_controller_rds_port" {
  description = "RDS instance port"
  value = aws_db_instance.controller.port
}
