output "vpc_id" {
  value       = aws_vpc.main.id
  description = "VPC's ID"
}

output "private_subnet_ids" {
  value       = aws_subnet.private[*].id
  description = "List of IDs for private subnets in the VPC"
}

