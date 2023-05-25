# VPC Definitions
module "spoke-vpc1" {
  source = "./terraform/vpc"

  vpc_name = "spoke-vpc1"
  primary_cidr = "10.2.0.0/23"
  add_secondary_cidr = true
  secondary_cidr = "100.64.0.0/16"
}

module "spoke-vpc2" {
  source = "./terraform/vpc"

  vpc_name = "spoke-vpc2"
  primary_cidr = "10.4.0.0/23"
  add_secondary_cidr = true
  secondary_cidr = "100.64.0.0/16"
}

module "eks-spoke1" {
  source = "./terraform/spoke-eks"

  cluster_name = "eks-spoke1"
  eks_private_subnet_ids = module.spoke-vpc1.eks_private_subnets
  eks_public_subnet_ids = module.spoke-vpc1.public_subnets
  enable_aws_load_balancer_controller = true
}

module "eks-spoke2" {
  source = "./terraform/spoke-eks"

  cluster_name = "eks-spoke2"
  eks_private_subnet_ids = module.spoke-vpc2.eks_private_subnets
  eks_public_subnet_ids = module.spoke-vpc2.public_subnets
  enable_aws_load_balancer_controller = true
}

resource "aws_ecr_repository" "nyancat" {
  name                 = "nyancat"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository" "whereami" {
  name                 = "whereami"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

