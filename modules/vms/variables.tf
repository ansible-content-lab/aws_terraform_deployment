variable "deployment_id" {
  description = "Creates a random string that will be used in tagging for correlating the resources used with a deployment of AAP."
  type = string
  validation {
    condition = (length(var.deployment_id) == 8 || length(var.deployment_id) == 0) && (can(regex("^[a-z]", var.deployment_id)) || var.deployment_id == "")
    error_message = "deployment_id length should be 8 chars and should contain lower case alphabets only"
  }
}

variable "instance_name_suffix" {}
variable "vm_name_prefix" {}
variable "instance_ami" {
  description = "The AMI to use for instances"
}
variable "subnet_id" {
  description = "The subnet ID in which to launch the instance (VPC)"
}

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

variable "vpc_security_group_ids" {
  description = "List of VPC security groups to associate"
  type = list(string)
  sensitive = true
}

variable "key_pair_name" {
  description = "(Optional) Key name of the Key Pair to use for the instance"
  type      = string
  nullable  = true
  default   = null
}
