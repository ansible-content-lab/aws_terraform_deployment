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
  region = var.aws_region
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

data "aws_ami" "instance_ami" {
  most_recent = true
  owners = ["309956199498"] # Red Hat's account ID

  filter {
    name = "name"
    values = ["RHEL-9.0*"]
  }
}

module "controller_vm" {
  source = "./modules/vms"

  count = var.infrastructure_controller_count
  deployment_id = var.deployment_id
  instance_name_suffix = random_string.instance_name_suffix.result
  vm_name_prefix = "controller-${count.index + 1}-"
  # desired ami id can be specified by replacing below line with `instance_ami = <desired-ami-id-here>`
  instance_ami = data.aws_ami.instance_ami.id
  instance_type = var.infrastructure_controller_type
  vpc_security_group_ids = [module.vpc.infrastructure_sg_id]
  subnet_id = module.vpc.infrastructure_subnets[0]
  key_pair_name = aws_key_pair.admin.key_name
}

module "hub_vm" {
  source = "./modules/vms"

  count = var.infrastructure_hub_count
  deployment_id = var.deployment_id
  instance_name_suffix = random_string.instance_name_suffix.result
  vm_name_prefix = "hub-${count.index + 1}-"
  # desired ami id can be specified by replacing below line with `instance_ami = <desired-ami-id-here>`
  instance_ami = data.aws_ami.instance_ami.id
  instance_type = var.infrastructure_hub_type
  vpc_security_group_ids = [module.vpc.infrastructure_sg_id]
  subnet_id = module.vpc.infrastructure_subnets[2]
}

module "execution_vm" {
  source = "./modules/vms"

  count = var.infrastructure_execution_count

  deployment_id = var.deployment_id
  instance_name_suffix = random_string.instance_name_suffix.result
  vm_name_prefix = "execution-${count.index + 1}-"
  # desired ami id can be specified by replacing below line with `instance_ami = <desired-ami-id-here>`
  instance_ami = data.aws_ami.instance_ami.id
  instance_type = var.infrastructure_execution_type
  vpc_security_group_ids = [module.vpc.infrastructure_sg_id]
  # subnet_id = index(module.vpc.infrastructure_subnets, "execution")
  subnet_id = module.vpc.infrastructure_subnets[1]
}

module "eda_vm" {
  source = "./modules/vms"

  count = var.infrastructure_eda_count

  deployment_id = var.deployment_id
  instance_name_suffix = random_string.instance_name_suffix.result
  vm_name_prefix = "eda-${count.index + 1}-"
  # desired ami id can be specified by replacing below line with `instance_ami = <desired-ami-id-here>`
  instance_ami = data.aws_ami.instance_ami.id
  instance_type = var.infrastructure_eda_type
  vpc_security_group_ids = [module.vpc.infrastructure_sg_id]
  # subnet_id = index(module.vpc.infrastructure_subnets, "eda")
  subnet_id = module.vpc.infrastructure_subnets[3]
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

resource "terraform_data" "private_key_copy" {
  
for_each = { for host, instance in flatten(module.controller_vm[*].vm_public_ip): host => instance }
  provisioner "file" {
    connection {
      type = "ssh"
      user = var.infrastructure_admin_username
      host = each.value
      private_key = file(var.infrastructure_private_key_filepath)
    }
      source      = "${var.infrastructure_private_key_filepath}"
      destination = "/home/ec2-user/.ssh/infrastructure_private_key.pem"
  }
}

resource "aws_key_pair" "admin" {
  key_name   = "admin-key"
  public_key =file(var.infrastructure_public_key_filepath)
}
resource "terraform_data" "copy_inventory" {
for_each = { for host, instance in flatten(module.controller_vm[*].vm_public_ip): host => instance }

  provisioner "file" {
    connection {
      type = "ssh"
      user = var.infrastructure_admin_username
      host = each.value
      private_key = file(var.infrastructure_private_key_filepath)
    }
     content = templatefile("${path.module}/templates/inventory.j2", { 
        aap_controller_hosts = module.controller_vm[*].vm_private_ip
        aap_ee_hosts = module.execution_vm[*].vm_private_ip
        aap_hub_hosts = module.hub_vm[*].vm_private_ip
        aap_eda_hosts = module.eda_vm[*].vm_private_ip
        aap_eda_allowed_hostnames = module.eda_vm[*].vm_public_ip
        infrastructure_db_username = var.infrastructure_db_username
        infrastructure_db_password = var.infrastructure_db_password
        aap_red_hat_username = var.aap_red_hat_username
        aap_red_hat_password= var.aap_red_hat_password
        aap_db_host = module.database.infrastructure_controller_rds_hostname
        aap_admin_password = var.aap_admin_password
        infrastructure_admin_username = var.infrastructure_admin_username
      })
      destination = var.infrastructure_aap_installer_inventory_path
  }
}
