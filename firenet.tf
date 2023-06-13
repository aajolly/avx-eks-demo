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
resource "aws_s3_bucket" "palo" {
  bucket = "paloalto-bootstrap-${local.region}"
}

resource "aws_s3_bucket_acl" "palo_s3_acl" {
	bucket = aws_s3_bucket.palo.id
	acl = "private"
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
    object_ownership = "ObjectWriter"
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
  firewall_name          = "aws-pan-fw"
  firewall_size          = "c5n.xlarge"
  vpc_id                 = aviatrix_vpc.transit_vpc.vpc_id
  firewall_image         = "Palo Alto Networks VM-Series Next-Generation Firewall Bundle 1"
  # firewall_image_version = "11.0.1"
  egress_subnet          = aviatrix_vpc.transit_vpc.public_subnets[1].subnet_id
  firenet_gw_name        = "aws-pan-fw"
  management_subnet      = aviatrix_vpc.transit_vpc.public_subnets[0].subnet_id
  # zone                   = local.use_gwlb ? local.az1 : (contains(["azure", "gcp"], local.cloud) ? local.zone : null)
  # firewall_image_id      = var.firewall_image_id
  tags                     = {
    name = "aws-pan-fw"
  }
  # username               = local.username
  # password               = local.password
  # ssh_public_key         = local.ssh_public_key
  # sic_key                = var.sic_key
  key_name               = var.key_name
  # availability_domain    = local.availability_domain
  # fault_domain           = local.fault_domain
  # management_vpc_id      = local.is_palo && local.cloud == "gcp" ? aviatrix_vpc.management_vpc[0].vpc_id : null
  # egress_vpc_id          = local.cloud == "gcp" ? aviatrix_vpc.egress_vpc[0].vpc_id : null

  #Bootstrapping
  # storage_access_key     = var.storage_access_key_1
  # file_share_folder      = var.file_share_folder_1
  # user_data              = var.user_data_1
  iam_role               = aws_iam_role.palo.name
  bootstrap_bucket_name  = "paloalto-bootstrap-${local.region}"

  lifecycle {
    ignore_changes = [
      firewall_size,          #Do not replace FW instance, after out of band resizing of instance
    ]
  }
}

resource "aviatrix_firewall_instance_association" "firenet_instance" {
  vpc_id          = aviatrix_vpc.transit_vpc.vpc_id
  firenet_gw_name = "aws-pan-fw"
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