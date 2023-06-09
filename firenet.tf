################################################
##############    Palo Alto FW    ##############
################################################

# IAM Resources

data "aws_iam_policy_document" "palo" {
  statement {
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::*"]
  }
  statement {
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["arn:aws:s3:::*"]
  }
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "palo" {
  name   = "aviatrix-bootstrap-VM-S3-policy"
  path   = "/"
  policy = data.aws_iam_policy_document.palo.json
}

resource "aws_iam_role" "palo" {
  name               = "aviatrix-bootstrap-VM-S3-role"
  description        = "palo alto vm series bootstrap"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "palo" {
  role       = aws_iam_role.palo.id
  policy_arn = aws_iam_policy.palo.arn
}

resource "aws_iam_instance_profile" "palo" {
  name = "aviatrix-bootstrap-VM-S3-role"
  role = aws_iam_role.palo.name
}

# S3 Resources
# Copy files to the remotestate bucket
resource "random_id" "s3" {
  byte_length = 8
}

resource "aws_s3_bucket" "palo" {
  bucket = "paloalto-bootstrap-${random_id.s3.hex}"
	tags = {
    Name        = "paloalto-bootstrap-${random_id.s3.hex}"
  }
}

resource "aws_s3_bucket_acl" "palo_s3_acl" {
	bucket = aws_s3_bucket.palo.id
	acl = "private"
	depends_on = [aws_s3_bucket_ownership_controls.s3_bucket_acl_ownership]
}

resource "aws_s3_bucket_server_side_encryption_configuration" "palo_s3_config" {
	bucket = aws_s3_bucket.palo.id

	rule {
		bucket_key_enabled = false
		apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
	}
	depends_on = [aws_s3_bucket_ownership_controls.s3_bucket_acl_ownership]
}

# Resource to avoid error "AccessControlListNotSupported: The bucket does not allow ACLs"
resource "aws_s3_bucket_ownership_controls" "s3_bucket_acl_ownership" {
  bucket = aws_s3_bucket.palo.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_object" "content" {
  bucket = aws_s3_bucket.palo.id
  acl    = "private"
  key    = "content/"
  source = "/dev/null"
}

resource "aws_s3_object" "license" {
  bucket = aws_s3_bucket.palo.id
  acl    = "private"
  key    = "license/"
  source = "/dev/null"
}

resource "aws_s3_object" "software" {
  bucket = aws_s3_bucket.palo.id
  acl    = "private"
  key    = "software/"
  source = "/dev/null"
}
resource "aws_s3_object" "bootstrap" {
  bucket = aws_s3_bucket.palo.id
  key    = "config/bootstrap.xml"
  source = "./paloalto/bootstrap.xml"
  etag   = filemd5("./paloalto/bootstrap.xml")
}

resource "aws_s3_object" "init_cfg" {
  bucket = aws_s3_bucket.palo.id
  key    = "config/init-cfg.txt"
  source = "./paloalto/init-cfg.txt"
  etag   = filemd5("./paloalto/init-cfg.txt")
}

#Firewall instances
resource "aviatrix_firewall_instance" "firewall_instance" {
  firenet_gw_name        = aviatrix_transit_gateway.transit_gateway_aws.gw_name
	firewall_name          = "aws-pan-fw"
  firewall_size          = "c5n.xlarge"
  vpc_id                 = aviatrix_vpc.transit_vpc.vpc_id
  firewall_image         = "Palo Alto Networks VM-Series Next-Generation Firewall Bundle 2"
  egress_subnet          = aviatrix_vpc.transit_vpc.public_subnets[1].cidr
	firewall_image_version = "11.0.1"
  management_subnet      = aviatrix_vpc.transit_vpc.public_subnets[0].cidr
  key_name               = var.key_name

  #Bootstrapping
  iam_role               = aws_iam_role.palo.name
  bootstrap_bucket_name  = aws_s3_bucket.palo.id
	tags                     = {
    name = "aws-pan-fw"
  }

  lifecycle {
    ignore_changes = [firewall_size]
  }
}

resource "aviatrix_firewall_instance_association" "firenet_instance" {
  vpc_id          = aviatrix_vpc.transit_vpc.vpc_id
  firenet_gw_name = aviatrix_transit_gateway.transit_gateway_aws.gw_name
  instance_id     = aviatrix_firewall_instance.firewall_instance.instance_id
  firewall_name   = aviatrix_firewall_instance.firewall_instance.firewall_name
  lan_interface = aviatrix_firewall_instance.firewall_instance.lan_interface
  management_interface = aviatrix_firewall_instance.firewall_instance.management_interface
  egress_interface     = aviatrix_firewall_instance.firewall_instance.egress_interface
  attached             = true
}

#Firenet
resource "aviatrix_firenet" "firenet" {
  vpc_id                               = aviatrix_vpc.transit_vpc.vpc_id

  depends_on = [aviatrix_firewall_instance_association.firenet_instance]
}

# Create an Aviatrix Transit FireNet Policy
resource "aviatrix_transit_firenet_policy" "test_transit_firenet_policy" {
  transit_firenet_gateway_name = aviatrix_transit_gateway.transit_gateway_aws.gw_name
  inspected_resource_name      = "SPOKE:${aviatrix_spoke_gateway.eks_spoke1_gw1.gw_name}"

	depends_on = [ 
		aviatrix_spoke_transit_attachment.eks_spk1_gw1_attach,
		aviatrix_spoke_transit_attachment.eks_spk2_gw1_attach ]
}