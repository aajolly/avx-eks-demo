# VPC Definitions
module "spoke-vpc1" {
  source = "./modules/vpc"

  vpc_name = "spoke-vpc1"
  primary_cidr = "10.2.0.0/23"
  add_secondary_cidr = true
  secondary_cidr = "100.64.0.0/16"
}

module "spoke-vpc2" {
  source = "./modules/vpc"

  vpc_name = "spoke-vpc2"
  primary_cidr = "10.4.0.0/23"
  add_secondary_cidr = true
  secondary_cidr = "100.64.0.0/16"
}

module "eks-spoke1" {
  source = "./modules/eks"

  cluster_name = "eks-spoke1"
  eks_private_subnet_ids = module.spoke-vpc1.eks_private_subnets
  eks_public_subnet_ids = module.spoke-vpc1.public_subnets
  enable_aws_load_balancer_controller = true
}

module "eks-spoke2" {
  source = "./modules/eks"

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

################################################
############## Aviatrix Resources ##############
################################################
# resource "aviatrix_vpc" "transit_vpc" {
#   cloud_type           = 1
#   account_name         = var.account_name
#   region               = data.aws_region.current.name
#   name                 = "transit-vpc"
#   cidr                 = "10.0.0.0/23"
#   # aviatrix_transit_vpc = true
#   aviatrix_firenet_vpc = true
# }

# Aviatrix Transit Gateway
resource "aviatrix_transit_gateway" "transit_gateway_aws" {
  cloud_type               = 1
  account_name             = var.account_name
  gw_name                  = "transit-gw"
  vpc_id                   = aviatrix_vpc.transit_vpc.vpc_id
  vpc_reg                  = data.aws_region.current.name
  gw_size                  = "t3.large"
  subnet                   = aviatrix_vpc.transit_vpc.public_subnets[0].cidr
  tags                     = {
    name = "transit-gw"
  }
  enable_hybrid_connection = true
  connected_transit        = true
  enable_transit_firenet = true
  excluded_advertised_spoke_routes = "100.64.0.0/16"
}

# Aviatrix Spoke Gateways
resource "aviatrix_spoke_gateway" "eks_spoke1_gw1" {
  cloud_type                        = 1
  account_name                      = var.account_name
  gw_name                           = "eks-spk1-gw1"
  vpc_id                            = module.spoke-vpc1.vpc_id
  vpc_reg                           = data.aws_region.current.name
  gw_size                           = "t3.micro"
  subnet                            = cidrsubnet(module.spoke-vpc1.vpc_cidr, 2, 0)
  single_ip_snat                    = false
  # manage_transit_gateway_attachment = false
  tags                              = {
    name = "eks_spk1_gw1"
  }
}

resource "aviatrix_spoke_gateway" "eks_spoke2_gw1" {
  cloud_type                        = 1
  account_name                      = var.account_name
  gw_name                           = "eks-spk2-gw1"
  vpc_id                            = module.spoke-vpc2.vpc_id
  vpc_reg                           = data.aws_region.current.name
  gw_size                           = "t3.micro"
  subnet                            = cidrsubnet(module.spoke-vpc2.vpc_cidr, 2, 0)
  single_ip_snat                    = false
  # manage_transit_gateway_attachment = false
  tags                              = {
    name = "eks_spk2_gw1"
  }
}

# Spoke to Transit attachments
resource "aviatrix_spoke_transit_attachment" "eks_spk1_gw1_attach" {
  spoke_gw_name   = "eks-spk1-gw1"
  transit_gw_name = "transit-gw"
  depends_on = [
    aviatrix_spoke_gateway.eks_spoke1_gw1,
    aviatrix_transit_gateway.transit_gateway_aws
  ]
}

resource "aviatrix_spoke_transit_attachment" "eks_spk2_gw1_attach" {
  spoke_gw_name   = "eks_spk2_gw1"
  transit_gw_name = "transit-gw"
  depends_on = [
    aviatrix_spoke_gateway.eks_spoke2_gw1,
    aviatrix_transit_gateway.transit_gateway_aws
  ]
}
# NAT Rules on Spoke Gateways
resource "aviatrix_gateway_snat" "eks_spk1_gw1_snat" {
  gw_name   = "eks-spk1-gw1"
  snat_mode = "customized_snat"
  snat_policy {
    src_cidr    = "100.64.0.0/16"
    dst_cidr    = "10.0.0.0/8"
    protocol    = "all"
    interface   = ""
    connection  = "transit-gw"
    snat_ips    = aviatrix_spoke_gateway.eks_spoke1_gw1.private_ip
  }
  depends_on = [
    aviatrix_spoke_transit_attachment.eks_spk1_gw1_attach
  ]
}
resource "aviatrix_gateway_snat" "eks_spk2_gw1_snat" {
  gw_name   = "eks-spk2-gw1"
  snat_mode = "customized_snat"
  snat_policy {
    src_cidr    = "100.64.0.0/16"
    dst_cidr    = "10.0.0.0/8"
    protocol    = "all"
    interface   = ""
    connection  = "transit-gw"
    snat_ips    = aviatrix_spoke_gateway.eks_spoke2_gw1.private_ip
  }
  depends_on = [
    aviatrix_spoke_transit_attachment.eks_spk2_gw1_attach
  ]
}