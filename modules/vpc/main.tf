terraform {
  required_version = ">= 1.5.4"
  required_providers {
    random = {
      source = "hashicorp/random"
      version = "~> 3.6.0"
    }
    aws = {
      source = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

########################################
# VPC
########################################
resource "aws_vpc" "aap_infrastructure_vpc" {
  cidr_block = var.infrastructure_vpc_cidr
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = merge(
    {
      Name = "aap-infrastructure-${var.deployment_id}-vpc"
    },
    var.persistent_tags
  )
}

########################################
# Subnets
########################################

# Declare data source for availablity zones
data "aws_availability_zones" "availability_zone_list" {
  state = "available"
}

resource "random_shuffle" "az" {
  input = data.aws_availability_zones.availability_zone_list.names
  result_count = length(var.infrastructure_vpc_subnets)
}

resource "aws_subnet" "aap_infrastructure_subnets" {
  count = length(var.infrastructure_vpc_subnets)
  vpc_id = aws_vpc.aap_infrastructure_vpc.id
  cidr_block = var.infrastructure_vpc_subnets[count.index]["cidr_block"]
  availability_zone = random_shuffle.az.result[count.index]

  tags = merge(
    {
      Name = "aap-infrastructure-${var.deployment_id}-subnet-${var.infrastructure_vpc_subnets[count.index]["name"]}"
    },
    var.persistent_tags
  )
  depends_on = [aws_vpc.aap_infrastructure_vpc]
}

########################################
# Internet gateway
########################################
resource "aws_internet_gateway" "aap_infrastructure_igw" {
  vpc_id = aws_vpc.aap_infrastructure_vpc.id
  tags = merge(
    {
      Name = "aap-infrastructure-${var.deployment_id}-igw"
    },
    var.persistent_tags
  )
  depends_on = [aws_vpc.aap_infrastructure_vpc]
}

########################################
# Security group 
########################################
resource "aws_security_group" "aap_infrastructure_sg" {
  name = "aap-infrastructure-${var.deployment_id}-sg"
  description = "AAP security group"
  vpc_id = aws_vpc.aap_infrastructure_vpc.id

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "allow external ports for SSH, HTTPS, and Automation Mesh"
  }

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "allow external ports for SSH, HTTPS, and Automation Mesh"
  }

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "allow external ports for SSH, HTTPS, and Automation Mesh"
  }

  ingress {
    from_port = 27199
    to_port = 27199
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "allow external ports for SSH, HTTPS, and Automation Mesh"
  }

  ingress {
    from_port = -1
    to_port = -1
    protocol = "icmp"
    cidr_blocks = [var.infrastructure_vpc_cidr]
    description = "allow ping on local net"
  }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [var.infrastructure_vpc_cidr]
    description = "allow aap ports on local net"
  }

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = [var.infrastructure_vpc_cidr]
    description = "allow aap ports on local net"
  }
  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = [var.infrastructure_vpc_cidr]
    description = "allow aap ports on local net"
  }
  ingress {
    from_port = 5432
    to_port = 5432
    protocol = "tcp"
    cidr_blocks = [var.infrastructure_vpc_cidr]
    description = "allow aap ports on local net"
  }
  ingress {
    from_port = 8443
    to_port = 8443
    protocol = "tcp"
    cidr_blocks = [var.infrastructure_vpc_cidr]
    description = "allow aap ports on local net"
  }
  ingress {
    from_port = 27199
    to_port = 27199
    protocol = "tcp"
    cidr_blocks = [var.infrastructure_vpc_cidr]
    description = "allow aap ports on local net"
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "allow all outbound"
  }

  tags = merge(
    {
      Name = "aap-infrastructure-${var.deployment_id}-sg"
    },
    var.persistent_tags
  )
  depends_on = [aws_vpc.aap_infrastructure_vpc]
}

########################################
# Route table 
########################################
resource "aws_route_table" "aap_infrastructure_route_table" {
  vpc_id = aws_vpc.aap_infrastructure_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.aap_infrastructure_igw.id
  }
  tags = merge(
    {
      Name = "aap-infrastructure-${var.deployment_id}-rt"
    },
    var.persistent_tags
  )
  depends_on = [aws_vpc.aap_infrastructure_vpc]
}

########################################
# Route table association
########################################

resource "aws_route_table_association" "aap_infrastructure_subnet_association" {
  for_each = { for key, subnet in aws_subnet.aap_infrastructure_subnets : key => subnet.id }
  subnet_id = each.value
  route_table_id = aws_route_table.aap_infrastructure_route_table.id
  depends_on = [aws_subnet.aap_infrastructure_subnets]
}
