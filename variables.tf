data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# data "http" "my_ip" {
#   url    = "https://api.ipify.org?format=json"
#   method = "GET"
# }

locals {
  account_id      = data.aws_caller_identity.current.account_id
  tool_prefix     = "avxctl"
  # my_public_ip    = "${jsondecode(data.http.my_ip.response_body).ip}/32"
  region          = coalesce(var.region, data.aws_region.current.name)
}

variable "region" {
  type = string
  default = ""
}
variable "controller_ip" {}
variable "controller_username" {}
variable "controller_password" {}
variable "account_name" {}