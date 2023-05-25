data "aws_region" "current" {}
data "aws_availability_zones" "az" {
  state = "available"
}

variable "primary_cidr" {
  type = string
	description = "Primary CIDR block to associate with VPC"
}
variable "secondary_cidr" {
  type = string
  default = "100.64.0.0/16"
	description = "Secondary CIDR Block to associate with VPC, default = 100.64.0.0/16"
}
variable "internet_cidr" {
  type = string
  description = "Internet CIDR"
  default = "0.0.0.0/0"
}
variable "vpc_name" {
  type = string
	description = "VPC Name"
}
variable "add_secondary_cidr" {
    type = bool
		description = "Add a Secondary VPC"
}
variable "tls_port" {
  type = number
  description = "Port for VPC Endpoint"
  default = 443
}

variable "protocol" {
  type = string
  description = "Protocol to use for VPC Endpoint"
  default = "tcp"
}