variable "deployment_id" {}
variable "instance_name_suffix" {}
variable "vm_name_prefix" {}
variable "latest_rhel9_ami" {}

variable "app_tag" {
  description = "Tag value for AAP component"
  validation {
    condition = var.app_tag == "controller" || var.app_tag == "hub"
    error_message = "Invalid app_tag. Valid values are 'controller' or 'hub'."
  }
  type = string
  default = "controller"
}

variable "instance_type" {
  description = "VM instance type"
  type = string
  default = "m5a.xlarge"
}
