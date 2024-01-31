variable "deployment_id" {
  description = "Creates a random string that will be used in tagging for correlating the resources used with a deployment of AAP."
  type = string
  validation {
    condition = ((length(var.deployment_id) >= 2 && length(var.deployment_id)<=10) || length(var.deployment_id) == 0) && (can(regex("^[a-z]", var.deployment_id)) || var.deployment_id == "")
    error_message = "deployment_id length should be between 2-10 chars and should contain lower case alpha chars only"
  }
}

variable "instance_name_suffix" {
  description = "EC2 instance name suffix"
  type = string
}
variable "vm_name_prefix" {
  description = "EC2 instance name prefix"
  type = string
}
variable "instance_ami" {
  description = "The AMI to use for instances"
  type = string
}
variable "subnet_id" {
  description = "The subnet ID in which to launch the instance (VPC)"
  type = string
}

variable "app_tag" {
  description = "Tag value for AAP component"
  type = string
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
  type = string
  nullable = true
  default = null
}

variable "persistent_tags" {
  description = "Persistent tags"
  type = map(string)
}

variable "infrastructure_volumes" {
  description = "Customize details about the root block device of the instance."
  type = object({
    volume_type = string
    volume_size = number
    iops = number
    delete_on_termination = bool
  })
  default = {
    volume_type = "io1"
    volume_size = 100
    iops = 1500
    delete_on_termination = true
  }
}

variable "infrastructure_admin_username" {
  type = string
  description = "The admin username of the VM that will be deployed."
  nullable = false
}

variable "infrastructure_ssh_private_key" {
  description = "Private ssh key file path."
  type = string
}
variable "aap_red_hat_username" {
  description = "Red Hat account name that will be used for Subscription Management."
  type = string
}

variable "aap_red_hat_password" {
  description = "Red Hat account password."
  type = string
  sensitive = true
}
