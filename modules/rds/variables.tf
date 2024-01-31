variable "allocated_storage" {
  description = "The allocated storage in gibibytes"
  type = number
  default = 100
}

variable "allow_major_version_upgrade" {
  description = "Indicates that major version upgrades are allowed"
  type = bool
  default = false
}

variable "auto_minor_version_upgrade" {
  description = "Indicates that minor engine upgrades will be applied automatically to the DB instance"
  type = bool
  default = true
}

variable "db_name" {
  description = "The name of the database to create "
  type = string
  default = "controller"
}

variable "db_sng_description" {
  description = "Subnet group description"
  type = string
}

variable "db_sng_name" {
  description = "Subnet group name"
  type = string
}

variable "db_sng_subnets" {
  description = "List of subnet IDs from the VPC"
  type = list(any)
}

variable "db_sng_tags" {
  description = "value"
  type = map(any)
}

variable "engine" {
  description = "The database engine to use"
  type = string
  default = "postgres"
}

variable "engine_version" {
  description = "The database engine version to use"
  type = string
  default = "13.12"
}

variable "instance_class" {
  description = "The instance type of the RDS instance"
  type = string
  default = "db.m5d.xlarge"
}

variable "multi_az" {
  description = "Specifies if the RDS instance is multi-AZ"
  type = bool
  default = false
}

variable "skip_final_snapshot" {
  description = "Skip the final snapshot on destroy"
  type = bool
  default = true
}

variable "storage_encrypted" {
  description = "Specifies whether the DB instance is encrypted"
  type = bool
  default = true
}

variable "storage_iops" {
  description = "The amount of provisioned IOPS"
  type = number
  default = 5000
}

variable "storage_type" {
  description = "The type of storage to use (defaults to io1 if iops is defined)"
  type = string
  default = "io1"
}

variable "username" {
  description = "Database instance username"
  type = string
  default = "ansible"
}

variable "password" {
  description = "Database instance password"
  type = string
  sensitive = true
  default = "changeme"
}

variable "vpc_security_group_ids" {
  description = "List of VPC security groups to associate"
  type = list(string)
  sensitive = true
}

variable "deployment_id" {
  description = "Creates a random string that will be used in tagging for correlating the resources used with a deployment of AAP."
  type = string
  validation {
    condition = ((length(var.deployment_id) >= 2 && length(var.deployment_id)<=10) || length(var.deployment_id) == 0) && (can(regex("^[a-z]", var.deployment_id)) || var.deployment_id == "")
    error_message = "deployment_id length should be between 2-10 chars and should contain lower case alpha chars only"
  }
}
variable "persistent_tags" {
  description = "Persistent tags"
  type = map(string)
}

variable "infrastructure_hub_count" {
  description = "The number of ec2 instances for hub"
  type = number
}

variable "infrastructure_eda_count" {
  description = "The number of EDA instances"
  type = number
}
