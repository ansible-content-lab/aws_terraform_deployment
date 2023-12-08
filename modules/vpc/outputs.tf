output "infrastructure_subnets" {
  value = {
    for key, subnet in aws_subnet.aap_infrastructure_subnets : key => subnet.id
  }

  depends_on = [aws_subnet.aap_infrastructure_subnets]
}

output "infrastructure_igw" {
  value = aws_internet_gateway.aap_infrastructure_igw.id
}
