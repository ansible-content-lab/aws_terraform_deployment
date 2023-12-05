output "infrastructure_subnets" {
  value = {
    for k, s in aws_subnet.aap_infrastructure_subnets : k => s.id
  }

  depends_on = [aws_subnet.aap_infrastructure_subnets]
}

output "infrastructure_igw" {
  value = aws_internet_gateway.aap_infrastructure_igw.id
}