output "vpc_id" {
  value       = aws_vpc.vpc.id
  description = "VPC ID"
}
output "public_subnets" {
    description = "VPC Public Subnets"
    value = [for az, subnet in aws_subnet.public_subnet: subnet.id]
}
output "private_subnets" {
    description = "VPC Private Subnets"
    value = [for az, subnet in aws_subnet.private_subnet: subnet.id]
}
output "eks_private_subnets" {
    description = "VPC Private Subnets - EKS"
    value = [for az, subnet in aws_subnet.eks_private_subnet: subnet.id]
}
output "vpc_cidr" {
    description = "VPC CIDR Block"
    value = aws_vpc.vpc.cidr_block
}