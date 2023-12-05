variable "infrastructure_vpc_cidr" {
  description = <<-EOT
    IPv4 CIDR netmask for the VPC resource.
  EOT
  type        = string
  default     = "172.16.0.0/22"
}

variable "deployment_id" {
  description = "Creates a random string that will be used in tagging for correlating the resources used with a deployment of AAP."
  type    = string
  validation {
    condition     = length(var.deployment_id) == 8 && can(regex("^[a-z]", var.deployment_id))
    error_message = "deployment_id length should be 8 chars and should contain lower case alphabets only"
  }
}

variable persistent_tags {}

variable "infrastructure_vpc_subnets" {
  type = list(object({
    name = string
    cidr_block = string
    availability_zone = string
  }))
  default = [{
    name = "controller"
    cidr_block = "172.16.0.0/24"
    availability_zone = "us-east-1a"
  },
   {
    name = "execution"
    cidr_block = "172.16.1.0/24"
    availability_zone = "us-east-1b"
  },
   {
    name = "hub"
    cidr_block = "172.16.2.0/24"
    availability_zone = "us-east-1c"
  },
  {
    name = "eda"
    cidr_block = "172.16.3.0/24"
    availability_zone = "us-east-1d"
  }]
}

variable "infrastructure_vpc_subnets_controller" {
  type        = string
  default     = "172.16.0.0/22"
}
variable "infrastructure_vpc_subnets_execution" {
  type        = string
  default     = "172.16.1.0/24"
}

variable "infrastructure_vpc_subnets_hub" {
  type        = string
  default     = "172.16.2.0/24"
}

variable "infrastructure_vpc_subnets_eda" {
  type        = string
  default     = "172.16.3.0/24"
}
