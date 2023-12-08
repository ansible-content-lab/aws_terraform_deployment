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
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    random = {
      source = "hashicorp/random"
      version = "~> 3.6.0"
    }
  }
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
