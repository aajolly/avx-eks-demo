terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 4.0"
    }
		aviatrix = {
      source = "AviatrixSystems/aviatrix"
      version = "3.1.0"
    }
  }
}
provider "aws" {
  region = var.region
}
# Configure Aviatrix provider
provider "aviatrix" {
  controller_ip           = var.controller_ip
  username                = var.controller_username
  password                = var.controller_password
  skip_version_validation = false
}