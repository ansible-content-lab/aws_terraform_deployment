variable "deployment_id" {
  description = "Creates a random string that will be used in tagging for correlating the resources used with a deployment of AAP."
  type = string
  validation {
    condition = (length(var.deployment_id) == 8 || length(var.deployment_id) == 0) && (can(regex("^[a-z]", var.deployment_id)) || var.deployment_id == "")
    error_message = "deployment_id length should be 8 chars and should contain lower case alphabets only"
  }
}

variable "aws_region" {
  description = "AWS Region to be used"
  type = string

  validation {
  condition = can(regex("[a-z][a-z]-[a-z]+-[1-9]", var.aws_region))
  error_message = "Must be valid AWS Region names."
}
}

# Database variables
variable "infrastructure_db_allocated_storage" {
  description = "The allocated storage in gibibytes"
  type = number
  default = 100
}

variable "infrastructure_db_allow_major_version_upgrade" {
  description = "Indicates that major version upgrades are allowed"
  type = bool
  default = false
}

variable "infrastructure_db_auto_minor_version_upgrade" {
  description = "Indicates that minor engine upgrades will be applied automatically to the DB instance"
  type = bool
  default = true
}
variable "infrastructure_db_instance_class" {
  description = "The instance type of the RDS instance"
  type = string
  default = "db.m5d.xlarge"
}

variable "infrastructure_db_engine_version" {
  description = "The database engine version to use"
  type = string
  default = "13.12"
}

variable "infrastructure_db_multi_az" {
  description = "Specifies if the RDS instance is multi-AZ"
  type = bool
  default = false
}

variable "infrastructure_db_storage_encrypted" {
  description = "Specifies whether the DB instance is encrypted"
  type = bool
  default = true
}

variable "infrastructure_db_storage_iops" {
  description = "The amount of provisioned IOPS"
  type = number
  default = 5000
}

variable "infrastructure_db_storage_type" {
  description = "The type of storage to use (defaults to io1 if iops is defined)"
  type = string
  default = "io1"
}

variable "infrastructure_db_username" {
  description = "Database instance username"
  type = string
  default = "ansible"
}

variable "infrastructure_db_password" {
  description = "Database instance password"
  type = string
  sensitive = true
  default = "changeme"
}
