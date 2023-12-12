locals {
  create_deployment_id = var.deployment_id != "" ? 0 : 1
  # Common tags to be assigned to all resources
  persistent_tags = {
    purpose = "automation"
    environment = "ansible-automation-platform"
    deployment = "aap-infrastructure-${var.deployment_id}"
  }
}

terraform {
  required_providers {
    random = {
      source = "hashicorp/random"
      version = "~> 3.6.0"
    }
  }
  required_version = ">= 1.5.4"
}
# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

resource "random_string" "deployment_id" {
  count = local.create_deployment_id
  length = 8
  special = false
  upper = false
  numeric = false
}

#
# VPC
#
module "vpc" {
  depends_on = [random_string.deployment_id]
  source = "./modules/vpc"
  deployment_id = var.deployment_id == "" ? random_string.deployment_id[0].id : var.deployment_id
  persistent_tags = local.persistent_tags
}

resource "random_string" "instance_name_suffix" {
  length = 8
  special  = false
  upper = false
  numeric = false
}

data "aws_ami" "latest_al2_linux_ami" {
  most_recent = true
  owners = ["amazon"]

  filter {
    name = "name"
    values = ["amzn2-ami-hvm-*-x86_64-ebs"]
  }
}

module "controller_vm" {
  source = "./modules/vms"

  deployment_id = var.deployment_id
  instance_name_suffix = random_string.instance_name_suffix.result
  vm_name_prefix = "controller-"
  # desired ami id can be specified by replacing below line with `latest_al2_linux_ami = <desired-ami-id-here>`
  latest_al2_linux_ami = data.aws_ami.latest_al2_linux_ami.id
}

module "database" {
  source = "./modules/database"

  allocated_storage = var.infrastructure_db_allocated_storage
  allow_major_version_upgrade = var.infrastructure_db_allow_major_version_upgrade
  auto_minor_version_upgrade = var.infrastructure_db_auto_minor_version_upgrade
  db_name = "controller"
  engine = "postgres"
  engine_version = var.infrastructure_db_engine_version
  identifier = "aap-infrastructure-${var.deployment_id}-db"
  instance_class = var.infrastructure_db_instance_class
  multi_az = var.infrastructure_db_multi_az
  db_sng_description =  "Ansible Automation Platform Subnet Group"
  db_sng_name = "aap-infrastructure-${var.deployment_id}-subnet-group"
  db_sng_subnets = values(module.vpc.infrastructure_subnets)

  db_sng_tags = merge(
    {
      Name = "aap-infrastructure-${var.deployment_id}-subnet-group"
    },
    local.persistent_tags
  ) 

  skip_final_snapshot = true
  storage_iops = var.infrastructure_db_storage_iops
  storage_encrypted = var.infrastructure_db_storage_encrypted
  storage_type = var.infrastructure_db_storage_type

  tags = merge(
    {
      Name = "aap-infrastructure-${var.deployment_id}-db"
    },
    local.persistent_tags
  )

  username = var.infrastructure_db_username
  password = var.infrastructure_db_password

  vpc_security_group_ids = [module.vpc.infrastructure_sg_id]
}
