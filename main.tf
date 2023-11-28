terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

resource "random_string" "deployment_id" {
  count = "${var.deployment_id != "" ? 0 : 1}"

  length   = 8
  special  = false
  upper = false
  numeric = false
}
