variable "enable_aws_load_balancer_controller" {
  type = bool
}
variable "cluster_name" {
  type = string
}
variable "eks_private_subnet_ids" {
  type = list
}
variable "eks_public_subnet_ids" {
  type = list
}
variable "vpc_id" {
  type = string
}