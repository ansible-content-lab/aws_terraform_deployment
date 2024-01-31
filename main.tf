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
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.15"
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

########################################
# VPC
########################################
module "vpc" {
  depends_on = [ random_string.deployment_id ]
  source = "./modules/vpc"
  deployment_id = var.deployment_id == "" ? random_string.deployment_id[0].id : var.deployment_id
  persistent_tags = local.persistent_tags
}

resource "random_string" "instance_name_suffix" {
  length = 8
  special = false
  upper = false
  numeric = false
}

data "aws_ami" "instance_ami" {
  most_recent = true
  owners = ["309956199498"] # Red Hat's account ID

  filter {
    name = "name"
    values = ["RHEL-9.2.*_HVM-*"]
  }
}

resource "aws_key_pair" "admin" {
  key_name = "admin-key"
  public_key = file(var.infrastructure_ssh_public_key)
}

########################################
# RDS Instance
########################################
module "rds" {
  depends_on = [ module.vpc ]
  source = "./modules/rds"

  deployment_id = var.deployment_id == "" ? random_string.deployment_id[0].id : var.deployment_id
  allocated_storage = var.infrastructure_db_allocated_storage
  allow_major_version_upgrade = var.infrastructure_db_allow_major_version_upgrade
  auto_minor_version_upgrade = var.infrastructure_db_auto_minor_version_upgrade
  engine_version = var.infrastructure_db_engine_version
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
  username = var.infrastructure_db_username
  password = var.infrastructure_db_password
  persistent_tags = local.persistent_tags
  vpc_security_group_ids = [module.vpc.infrastructure_sg_id]
  infrastructure_hub_count = var.infrastructure_hub_count
  infrastructure_eda_count = var.infrastructure_eda_count
}

########################################
# Controller VM 
########################################

module "controller_vm" {
  depends_on = [ module.vpc ]
  source = "./modules/vms"

  app_tag = "controller"
  count = var.infrastructure_controller_count
  deployment_id = var.deployment_id == "" ? random_string.deployment_id[0].id : var.deployment_id
  instance_name_suffix = random_string.instance_name_suffix.result
  vm_name_prefix = "controller-${count.index + 1}-"
  instance_ami = var.infrastructure_hub_ami == "" ? data.aws_ami.instance_ami.id : var.infrastructure_controller_ami
  instance_type = var.infrastructure_controller_instance_type
  vpc_security_group_ids = [module.vpc.infrastructure_sg_id]
  subnet_id = module.vpc.infrastructure_subnets[0]
  key_pair_name = aws_key_pair.admin.key_name
  persistent_tags = local.persistent_tags
  infrastructure_ssh_private_key = var.infrastructure_ssh_private_key
  infrastructure_admin_username = var.infrastructure_admin_username
  aap_red_hat_username = var.aap_red_hat_username
  aap_red_hat_password = var.aap_red_hat_password
}

########################################
# Hub VM
########################################
module "hub_vm" {
  depends_on = [ module.vpc ]
  source = "./modules/vms"

  app_tag = "hub"
  count = var.infrastructure_hub_count
  deployment_id = var.deployment_id == "" ? random_string.deployment_id[0].id : var.deployment_id
  instance_name_suffix = random_string.instance_name_suffix.result
  vm_name_prefix = "hub-${count.index + 1}-"
  instance_ami = var.infrastructure_hub_ami == "" ? data.aws_ami.instance_ami.id : var.infrastructure_hub_ami
  instance_type = var.infrastructure_hub_instance_type
  vpc_security_group_ids = [module.vpc.infrastructure_sg_id]
  subnet_id = module.vpc.infrastructure_subnets[2]
  key_pair_name = aws_key_pair.admin.key_name
  persistent_tags = local.persistent_tags
  infrastructure_ssh_private_key = var.infrastructure_ssh_private_key
  infrastructure_admin_username = var.infrastructure_admin_username
  aap_red_hat_username = var.aap_red_hat_username
  aap_red_hat_password = var.aap_red_hat_password
}

########################################
# Execution VM
########################################
module "execution_vm" {
  depends_on = [ module.vpc ]
  source = "./modules/vms"

  count = var.infrastructure_execution_count
  app_tag = "execution"
  deployment_id = var.deployment_id == "" ? random_string.deployment_id[0].id : var.deployment_id
  instance_name_suffix = random_string.instance_name_suffix.result
  vm_name_prefix = "execution-${count.index + 1}-"
  instance_ami = var.infrastructure_hub_ami == "" ? data.aws_ami.instance_ami.id : var.infrastructure_execution_ami
  instance_type = var.infrastructure_execution_instance_type
  vpc_security_group_ids = [module.vpc.infrastructure_sg_id]
  # subnet_id = index(module.vpc.infrastructure_subnets, "execution")
  subnet_id = module.vpc.infrastructure_subnets[1]
  key_pair_name = aws_key_pair.admin.key_name
  persistent_tags = local.persistent_tags
  infrastructure_ssh_private_key = var.infrastructure_ssh_private_key
  infrastructure_admin_username = var.infrastructure_admin_username
  aap_red_hat_username = var.aap_red_hat_username
  aap_red_hat_password = var.aap_red_hat_password
}

########################################
# Event-Driven Ansible VM
########################################
module "eda_vm" {
  depends_on = [ module.vpc ]
  source = "./modules/vms"

  count = var.infrastructure_eda_count
  app_tag = "eda"
  deployment_id = var.deployment_id == "" ? random_string.deployment_id[0].id : var.deployment_id
  instance_name_suffix = random_string.instance_name_suffix.result
  vm_name_prefix = "eda-${count.index + 1}-"
  instance_ami = var.infrastructure_hub_ami == "" ? data.aws_ami.instance_ami.id : var.infrastructure_eda_ami
  instance_type = var.infrastructure_eda_instance_type
  vpc_security_group_ids = [ module.vpc.infrastructure_sg_id ]
  # subnet_id = index(module.vpc.infrastructure_subnets, "eda")
  subnet_id = module.vpc.infrastructure_subnets[3]
  key_pair_name = aws_key_pair.admin.key_name
  persistent_tags = local.persistent_tags
  infrastructure_ssh_private_key = var.infrastructure_ssh_private_key
  infrastructure_admin_username = var.infrastructure_admin_username
  aap_red_hat_username = var.aap_red_hat_username
  aap_red_hat_password = var.aap_red_hat_password
}

resource "terraform_data" "inventory" {
  for_each = { for host, instance in flatten(module.controller_vm[*].vm_public_ip): host => instance }
  connection {
      type = "ssh"
      user = var.infrastructure_admin_username
      host = each.value
      private_key = file(var.infrastructure_ssh_private_key)
    }
  provisioner "file" {
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
      aap_controller_db_host = module.rds.infrastructure_controller_rds_hostname
      aap_hub_db_host = module.rds.infrastructure_hub_rds_hostname
      aap_eda_db_host = module.rds.infrastructure_eda_rds_hostname
      aap_admin_password = var.aap_admin_password
      infrastructure_admin_username = var.infrastructure_admin_username
    })
    destination = var.infrastructure_aap_installer_inventory_path
  }
  provisioner "file" {
    content = templatefile("${path.module}/templates/config.j2", { 
      aap_controller_hosts = module.controller_vm[*].vm_private_ip
      aap_ee_hosts = module.execution_vm[*].vm_private_ip
      aap_hub_hosts = module.hub_vm[*].vm_private_ip
      aap_eda_hosts = module.eda_vm[*].vm_private_ip
      infrastructure_admin_username = var.infrastructure_admin_username
    })
    destination = "/home/${var.infrastructure_admin_username}/.ssh/config"
  }
  provisioner "remote-exec" {
      inline = [
        "chmod 0644 /home/${var.infrastructure_admin_username}/.ssh/config",
        "sudo cp /home/${var.infrastructure_admin_username}/.ssh/config /root/.ssh/config",
      ]
  }
}
