output "deployment_id" {
  description = "Print Deployment ID"
  value = var.deployment_id == "" ? random_string.deployment_id[0].id : var.deployment_id
}

output "vpc_module_outputs" {
  description = "VPC outputs"
  value = module.vpc
}

output "database_module_outputs" {
  description = "Database outputs"
  value = module.database
}
