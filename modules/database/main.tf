terraform {
  required_version = ">= 1.5.4"
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

resource "aws_db_subnet_group" "aap_infrastructure_db_subnet_group" {
  description = var.db_sng_description
  name        = var.db_sng_name
  subnet_ids  = var.db_sng_subnets

  tags = var.db_sng_tags
}
resource "aws_db_instance" "controller" {
  allocated_storage = var.allocated_storage
  allow_major_version_upgrade = var.allow_major_version_upgrade
  auto_minor_version_upgrade = var.auto_minor_version_upgrade
  db_name = var.db_name
  db_subnet_group_name = var.db_sng_name
  engine = var.engine
  engine_version = var.engine_version
  identifier = var.identifier
  instance_class = var.instance_class
  iops = var.storage_iops
  multi_az = var.multi_az
  skip_final_snapshot = var.skip_final_snapshot
  storage_encrypted = var.storage_encrypted
  storage_type = var.storage_type
  tags = var.tags

  username = var.username
  password = var.password

  vpc_security_group_ids = var.vpc_security_group_ids

  depends_on = [aws_db_subnet_group.aap_infrastructure_db_subnet_group]
}
