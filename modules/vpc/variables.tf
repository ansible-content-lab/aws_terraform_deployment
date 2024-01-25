variable "infrastructure_vpc_cidr" {
  description = "IPv4 CIDR netmask for the VPC resource."
  type = string
  default = "172.16.0.0/22"
}

variable "deployment_id" {
  description = "Creates a random string that will be used in tagging for correlating the resources used with a deployment of AAP."
  type = string
  validation {
    condition = ((length(var.deployment_id) >= 2 && length(var.deployment_id)<=10) || length(var.deployment_id) == 0) && (can(regex("^[a-z]", var.deployment_id)) || var.deployment_id == "")
    error_message = "deployment_id length should be between 2-10 chars and should contain lower case alpha chars only"
  }
}

variable persistent_tags {
  description = "Persistent tags"
  type = map(string)
}

variable "infrastructure_vpc_subnets" {
  type = list(object({
    name = string
    cidr_block = string
  }))
  default = [{
    name = "controller"
    cidr_block = "172.16.0.0/24"
  },
   {
    name = "execution"
    cidr_block = "172.16.1.0/24"
  },
   {
    name = "hub"
    cidr_block = "172.16.2.0/24"
  },
  {
    name = "eda"
    cidr_block = "172.16.3.0/24"
  }]
}
