data "aws_region" "current" {}
data "aws_availability_zones" "az" {
  state = "available"
}
#---------------------------------------------------------------
## VPC Resources - Subnets, Route Tables etc
#---------------------------------------------------------------
resource "aws_vpc" "vpc" {
  cidr_block           = var.primary_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = var.vpc_name
  }
}
resource "aws_vpc_ipv4_cidr_block_association" "eks_secondary_cidr" {
	count = var.add_secondary_cidr ? 1 : 0
  vpc_id     = aws_vpc.vpc.id
  cidr_block = var.secondary_cidr
}
#------------------------------------------
#### Internet Gateway
#------------------------------------------
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "${var.vpc_name}-igw"
  }
}
#------------------------------------------
#### Subnets
#------------------------------------------
resource "aws_subnet" "public_subnet" {
  count             = 2
  availability_zone = data.aws_availability_zones.az.names[count.index]
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = cidrsubnet(aws_vpc.vpc.cidr_block, 2, count.index)
  tags = {
    Name                                       = "${var.vpc_name}-public_subnet_${count.index + 1}"
    Reach                                      = "Public"
  }
}

resource "aws_subnet" "private_subnet" {
  count             = 2
  availability_zone = data.aws_availability_zones.az.names[count.index]
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = cidrsubnet(aws_vpc.vpc.cidr_block, 2, count.index + 2)
  tags = {
    Name                                       = "${var.vpc_name}-private_subnet_${count.index + 1}"
    Reach                                      = "Private"
	}
}
# Worker Node Subnets from Secondary CIDR
resource "aws_subnet" "eks_private_subnet" {
	count = var.add_secondary_cidr ? 2 : 0
  availability_zone = data.aws_availability_zones.az.names[count.index]
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = cidrsubnet(var.secondary_cidr, 4, count.index)
  tags = {
    Name                                       = "${var.vpc_name}-eks-private_subnet_${count.index + 1}"
    Reach                                      = "Private"
  }
  depends_on = [
    aws_vpc_ipv4_cidr_block_association.eks_secondary_cidr
    ]
}
#------------------------------------------
#### Route Tables
#------------------------------------------

resource "aws_route_table" "public_rt" {
  count    = 2
  vpc_id   = aws_vpc.vpc.id
  tags = {
    Name = "${var.vpc_name}-public_rt_${count.index + 1}"
  }
  route {
    cidr_block = var.internet_cidr
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table" "private_rt" {
  count    = 2
  vpc_id   = aws_vpc.vpc.id
  tags = {
    Name = "${var.vpc_name}-private_rt_${count.index + 1}"
  }
}
#------------------------------------------
#### Route Table Associations
#------------------------------------------
resource "aws_route_table_association" "public_rt_assoc" {
  count          = 2
  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.public_rt[count.index].id
}

resource "aws_route_table_association" "private_rt_assoc" {
  count          = 2
  subnet_id      = aws_subnet.private_subnet[count.index].id
  route_table_id = aws_route_table.private_rt[count.index].id
}
resource "aws_route_table_association" "worker_node_private_rt_assoc" {
  count = var.add_secondary_cidr ? 2 : 0
  subnet_id      = aws_subnet.eks_private_subnet[count.index].id
  route_table_id = aws_route_table.private_rt[count.index].id
}

#------------------------------------------
#### VPC Endpoints
#------------------------------------------
resource "aws_security_group" "vpce_sg" {
  name        = "${var.vpc_name}-vpce_secgrp"
  description = "Allow TLS"
  vpc_id      = aws_vpc.vpc.id
  tags = {
    Name = "aajolly_vpce_sg"
  }
}
resource "aws_security_group_rule" "allow_all" {
  description = "Allow All Egress"
  type              = "egress"
  to_port           = 0
  from_port         = 0
  protocol          = "-1"
  cidr_blocks = [var.internet_cidr]
  security_group_id = aws_security_group.vpce_sg.id
}
resource "aws_security_group_rule" "tls_vpc" {
  description = "TLS from VPC"
  type = "ingress"
  from_port = var.tls_port
  to_port = var.tls_port
  protocol = var.protocol
  cidr_blocks = aws_vpc.vpc.cidr_block
  security_group_id = aws_security_group.vpce_sg.id
}

resource "aws_vpc_endpoint" "ec2" {
  vpc_id            = aws_vpc.vpc.id
  service_name      = "com.amazonaws.${data.aws_region.current}.ec2"
  vpc_endpoint_type = "Interface"
  subnet_ids        = [for az, subnet in aws_subnet.private_subnet: subnet.id]
  security_group_ids = [
    aws_security_group.vpce_sg.id,
  ]

  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ec2Messages" {
  vpc_id            = aws_vpc.vpc.id
  service_name      = "com.amazonaws.${data.aws_region.current}.ec2messages"
  vpc_endpoint_type = "Interface"
  subnet_ids        = [for az, subnet in aws_subnet.private_subnet: subnet.id]
  security_group_ids = [
    aws_security_group.vpce_sg.id,
  ]

  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ssm" {
  vpc_id            = aws_vpc.vpc.id
  service_name      = "com.amazonaws.${data.aws_region.current}.ssm"
  vpc_endpoint_type = "Interface"
  subnet_ids        = [for az, subnet in aws_subnet.private_subnet: subnet.id]
  security_group_ids = [
    aws_security_group.vpce_sg.id,
  ]

  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id            = aws_vpc.vpc.id
  service_name      = "com.amazonaws.${data.aws_region.current}.ssmmessages"
  vpc_endpoint_type = "Interface"
  subnet_ids        = [for az, subnet in aws_subnet.private_subnet: subnet.id]
  security_group_ids = [
    aws_security_group.vpce_sg.id,
  ]

  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ecr-api" {
  vpc_id            = aws_vpc.vpc.id
  service_name      = "com.amazonaws.${data.aws_region.current}.ecr.api"
  vpc_endpoint_type = "Interface"
  subnet_ids        = [for az, subnet in aws_subnet.private_subnet: subnet.id]
  security_group_ids = [
    aws_security_group.vpce_sg.id,
  ]

  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ecr-dkr" {
  vpc_id            = aws_vpc.vpc.id
  service_name      = "com.amazonaws.${data.aws_region.current}.ecr.dkr"
  vpc_endpoint_type = "Interface"
  subnet_ids        = [for az, subnet in aws_subnet.private_subnet: subnet.id]
  security_group_ids = [
    aws_security_group.vpce_sg.id,
  ]

  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "cwlogs" {
  vpc_id            = aws_vpc.vpc.id
  service_name      = "com.amazonaws.${data.aws_region.current}.logs"
  vpc_endpoint_type = "Interface"
  subnet_ids        = [for az, subnet in aws_subnet.private_subnet: subnet.id]
  security_group_ids = [
    aws_security_group.vpce_sg.id,
  ]

  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "sts" {
  vpc_id            = aws_vpc.vpc.id
  service_name      = "com.amazonaws.${data.aws_region.current}.sts"
  vpc_endpoint_type = "Interface"
  subnet_ids        = [for az, subnet in aws_subnet.private_subnet: subnet.id]
  security_group_ids = [
    aws_security_group.vpce_sg.id,
  ]

  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "elasticloadbalancing" {
  vpc_id            = aws_vpc.vpc.id
  service_name      = "com.amazonaws.${data.aws_region.current}.elasticloadbalancing"
  vpc_endpoint_type = "Interface"
  subnet_ids        = [for az, subnet in aws_subnet.private_subnet: subnet.id]
  security_group_ids = [
    aws_security_group.vpce_sg.id,
  ]

  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "autoscaling" {
  vpc_id            = aws_vpc.vpc.id
  service_name      = "com.amazonaws.${data.aws_region.current}.autoscaling"
  vpc_endpoint_type = "Interface"
  subnet_ids        = [for az, subnet in aws_subnet.private_subnet: subnet.id]
  security_group_ids = [
    aws_security_group.vpce_sg.id,
  ]

  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.vpc.id
  service_name = "com.amazonaws.${data.aws_region.current}.s3"
}

resource "aws_vpc_endpoint_route_table_association" "route_table_assoc" {
  count = 2
  route_table_id = aws_route_table.private_rt[count.index]
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
}