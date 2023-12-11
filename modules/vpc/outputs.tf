output "infrastructure_subnets" {
  description = "List of subnets"
  value = {
    for key, subnet in aws_subnet.aap_infrastructure_subnets : key => subnet.id
  }

  depends_on = [aws_subnet.aap_infrastructure_subnets]
}

output "infrastructure_igw" {
  description = "Internet gateway ID"
  value = aws_internet_gateway.aap_infrastructure_igw.id
}
