output "deployment_id" {
  value = "${var.deployment_id == "" ? random_string.deployment_id[0].id : var.deployment_id }"
}
