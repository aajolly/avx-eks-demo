data "aws_region" "current" {}
#--------------------------------------------------
## IAM Resources - Policies, Roles
#--------------------------------------------------
data "aws_iam_policy_document" "eks_cluster_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "eks_cluster_role" {
  name = "${var.cluster_name}-cluster-role"
  assume_role_policy = data.aws_iam_policy_document.eks_cluster_assume_role_policy.json
  tags = {
    "Name" = "${var.cluster_name}-cluster-role"
  }
}

resource "aws_iam_role_policy_attachment" "eks_cluster_role_policy_attach" {
  role = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

data "aws_iam_policy_document" "eks_node_policy" {
  statement {
    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeTags",
      "autoscaling:SetDesiredCapacity",
      "autoscaling:TerminateInstanceInAutoScalingGroup",
      "ec2:DescribeInstanceTypes",
      "ec2:DescribeLaunchTemplateVersions"
    ]
    resources = ["*"]
    condition {
      test = "StringEquals"
      variable = "ec2:CreateAction"
      values = ["CreateSecurityGroup"]
    }
    condition {
      test = "Null"
      variable = "aws:RequestTag/elbv2.k8s.aws/cluster"
      values = ["false"]
    }
  }
  statement {
    actions = [
      "ec2:CreateTags"
    ]
    resources = ["arn:aws:ec2:*:*:security-group/*"]
    condition {
      test = "Null"
      variable = "aws:RequestTag/elbv2.k8s.aws/cluster"
      values = ["true"]
    }
    condition {
      test = "Null"
      variable = "aws:ResourceTag/elbv2.k8s.aws/cluster"
      values = ["false"]
    }
  }
  statement {
    actions = [
      "ec2:CreateTags",
      "ec2:DeleteTags"
    ]
    resources = ["arn:aws:ec2:*:*:security-group/*"]
    condition {
      test = "Null"
      variable = "aws:RequestTag/elbv2.k8s.aws/cluster"
      values = ["false"]
    }
  }
  statement {
    actions = [
      "elasticloadbalancing:AddTags",
      "elasticloadbalancing:RemoveTags",
      "elasticloadbalancing:RegisterTargets",
      "elasticloadbalancing:DeregisterTargets"
    ]
    resources = [
      "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*",
      "arn:aws:elasticloadbalancing:*:*:loadbalancer/net/*/*",
      "arn:aws:elasticloadbalancing:*:*:loadbalancer/app/*/*"
    ]
  }
  statement {
    actions = [
      "elasticloadbalancing:AddTags",
      "elasticloadbalancing:RemoveTags"
    ]
    resources = [
      "arn:aws:elasticloadbalancing:*:*:listener/net/*/*/*",
      "arn:aws:elasticloadbalancing:*:*:listener/app/*/*/*",
      "arn:aws:elasticloadbalancing:*:*:listener-rule/net/*/*/*",
      "arn:aws:elasticloadbalancing:*:*:listener-rule/app/*/*/*"
    ]
    condition {
      test = "Null"
      variable = "aws:ResourceTag/elbv2.k8s.aws/cluster"
      values = ["false"]
    }
  }
  statement {
    actions = [
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:RevokeSecurityGroupIngress",
      "ec2:DeleteSecurityGroup",
      "elasticloadbalancing:ModifyLoadBalancerAttributes",
      "elasticloadbalancing:SetIpAddressType",
      "elasticloadbalancing:SetSecurityGroups",
      "elasticloadbalancing:SetSubnets",
      "elasticloadbalancing:DeleteLoadBalancer",
      "elasticloadbalancing:ModifyTargetGroup",
      "elasticloadbalancing:ModifyTargetGroupAttributes",
      "elasticloadbalancing:DeleteTargetGroup"
    ]
    resources = ["*"]
  }
  statement {
    actions = [
      "iam:CreateServiceLinkedRole",
      "ec2:DescribeAccountAttributes",
      "ec2:DescribeAddresses",
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeInternetGateways",
      "ec2:DescribeVpcs",
      "ec2:DescribeSubnets",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeInstances",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DescribeTags",
      "ec2:DescribeVpcPeeringConnections",
      "elasticloadbalancing:DescribeLoadBalancers",
      "elasticloadbalancing:DescribeLoadBalancerAttributes",
      "elasticloadbalancing:DescribeListeners",
      "elasticloadbalancing:DescribeListenerCertificates",
      "elasticloadbalancing:DescribeSSLPolicies",
      "elasticloadbalancing:DescribeRules",
      "elasticloadbalancing:DescribeTargetGroups",
      "elasticloadbalancing:DescribeTargetGroupAttributes",
      "elasticloadbalancing:DescribeTargetHealth",
      "elasticloadbalancing:DescribeTags",
      "cognito-idp:DescribeUserPoolClient",
      "acm:ListCertificates",
      "acm:DescribeCertificate",
      "iam:ListServerCertificates",
      "iam:GetServerCertificate",
      "waf-regional:GetWebACL",
      "waf-regional:GetWebACLForResource",
      "waf-regional:AssociateWebACL",
      "waf-regional:DisassociateWebACL",
      "wafv2:GetWebACL",
      "wafv2:GetWebACLForResource",
      "wafv2:AssociateWebACL",
      "wafv2:DisassociateWebACL",
      "shield:GetSubscriptionState",
      "shield:DescribeProtection",
      "shield:CreateProtection",
      "shield:DeleteProtection",
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:RevokeSecurityGroupIngress",
      "ec2:CreateSecurityGroup",
      "elasticloadbalancing:CreateListener",
      "elasticloadbalancing:DeleteListener",
      "elasticloadbalancing:CreateRule",
      "elasticloadbalancing:DeleteRule",
      "elasticloadbalancing:SetWebAcl",
      "elasticloadbalancing:ModifyListener",
      "elasticloadbalancing:AddListenerCertificates",
      "elasticloadbalancing:RemoveListenerCertificates",
      "elasticloadbalancing:ModifyRule"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "eks_node_role_policy" {
  name = "${var.cluster_name}-node-role-policy"
  policy = data.aws_iam_policy_document.eks_node_policy.json
}

data "aws_iam_policy_document" "worker_node_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}
## Worker Node IAM Role
resource "aws_iam_role" "eks_worker_node_iam_role" {
  name = "${var.cluster_name}-node-group-role"
  assume_role_policy = data.aws_iam_policy_document.worker_node_assume_role_policy.json
  tags = {
    "Name" = "${var.cluster_name}-node-group-role"
  }
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_role_policy_attach1" {
  role = aws_iam_role.eks_worker_node_iam_role.name
  policy_arn = aws_iam_policy.eks_node_role_policy.arn
}

resource "aws_iam_role_policy_attachment" "AmazonSSMManagedInstanceCore" {
  role = aws_iam_role.eks_worker_node_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  role = aws_iam_role.eks_worker_node_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
  role = aws_iam_role.eks_worker_node_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "CloudWatchAgentServerPolicy" {
  role = aws_iam_role.eks_worker_node_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryPowerUser" {
  role = aws_iam_role.eks_worker_node_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  role = aws_iam_role.eks_worker_node_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

#---------------------------------------------------------------
## EKS Resources - Cluster, Worker nodes, CW Log Group
#---------------------------------------------------------------
resource "aws_cloudwatch_log_group" "eks_cwlogs" {
  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = 7
}

resource "aws_eks_cluster" "eks" {
  depends_on = [
    aws_cloudwatch_log_group.eks_cwlogs
    ]
  name       = var.cluster_name
  role_arn   = aws_iam_role.eks_cluster_role.arn
  enabled_cluster_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]

  vpc_config {
    subnet_ids = var.eks_public_subnet_ids
    endpoint_private_access = true
    endpoint_public_access = true
  }

}
resource "aws_eks_node_group" "eks_worker_node_group" {

  cluster_name    = aws_eks_cluster.eks.name
  node_group_name = "${aws_eks_cluster.eks.name}-workernodes"
  node_role_arn   = aws_iam_role.eks_worker_node_iam_role.arn
  subnet_ids      = var.eks_private_subnet_ids
	
  instance_types  = ["t3.xlarge"]

  scaling_config {
    desired_size = 2
    max_size     = 2
    min_size     = 2
  }
  update_config {
    max_unavailable = 1
  }
}

data "tls_certificate" "eks-cluster" {
  url = aws_eks_cluster.eks.identity[0].oidc[0].issuer
}
resource "aws_iam_openid_connect_provider" "eks-cluster" {
  client_id_list = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks-cluster.certificates[0].sha1_fingerprint]
  url = aws_eks_cluster.eks.identity[0].oidc[0].issuer
}

# EKS Add-ONs
resource "aws_eks_addon" "vpc-cni" {
  cluster_name = aws_eks_cluster.eks.name
  addon_name   = "vpc-cni"
}
resource "aws_eks_addon" "coredns" {
  cluster_name = aws_eks_cluster.eks.name
  addon_name = "coredns"
}
resource "aws_eks_addon" "kube-proxy" {
  cluster_name = aws_eks_cluster.eks.name
  addon_name = "kube-proxy"
}
#---------------------------------------------------------------
## AWS Load Balancer IAM Resources
#---------------------------------------------------------------
data "http" "aws_lb_controller_policy" {
  url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.4.4/docs/install/iam_policy.json"
  request_headers = {
    "Accept" = "application/json"
  }
}

resource "aws_iam_policy" "aws_load_balancer_controller_policy" {
  count = var.enable_aws_load_balancer_controller ? 1 : 0
  name = "${var.cluster_name}-AWSLoadBalancerControllerIAMPolicy"
  policy = data.http.aws_lb_controller_policy.response_body
}

data "aws_iam_policy_document" "aws_lbc_role_trust_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type = "Federated"
      identifiers = [aws_iam_openid_connect_provider.eks-cluster.arn]
    }
    condition {
      test = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks-cluster.url, "https://", "")}:sub"
      values = ["sts.amazonaws.com"]
    }
    condition {
      test = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks-cluster.url, "https://", "")}:aud"
      values = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
    }
  }
}

resource "aws_iam_role" "aws_lbc_role" {
  count = var.enable_aws_load_balancer_controller ? 1 : 0
  name = "${aws_eks_cluster.eks.name}-AmazonEKSLoadBalancerControllerRole"
  assume_role_policy = data.aws_iam_policy_document.aws_lbc_role_trust_policy.json
  tags = {
    "Name" = "${aws_eks_cluster.eks.name}-AmazonEKSLoadBalancerControllerRole"
  }
}

resource "aws_iam_role_policy_attachment" "aws_lbc_role_policy_attach" {
  count = var.enable_aws_load_balancer_controller ? 1 : 0
  role = aws_iam_role.aws_lbc_role[count.index].name
  policy_arn = aws_iam_policy.aws_load_balancer_controller_policy[count.index].arn
}

# Update Kubeconfig
resource "null_resource" "merge_kubeconfig" {
  triggers = {
    always = timestamp()
  }

  depends_on = [aws_eks_cluster.eks]

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = <<EOT
      set -e
      echo 'Applying Auth ConfigMap with kubectl...'
      aws eks wait cluster-active --name '${aws_eks_cluster.eks.name}'
      aws eks update-kubeconfig --name '${aws_eks_cluster.eks.name}' --alias '${aws_eks_cluster.eks.name}-${data.aws_region.current}' --region=${data.aws_region.current}
    EOT
  }
}

provider "kubernetes" {
  host                   = aws_eks_cluster.eks.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.eks.certificate_authority.0.data)
  exec {
      api_version = "client.authentication.k8s.io/v1alpha1"
      args        = ["eks", "get-token", "--cluster-name", var.cluster_name]
      command     = "aws"
    }
}

resource "kubernetes_service_account" "aws_load_balancer_controller_sa" {
  count = var.enable_aws_load_balancer_controller ? 1 : 0
  metadata {
    name = "aws-load-balancer-controller"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.aws_lbc_role[count.index].arn
    }
    labels = {
      "app.kubernetes.io/component" = "controller"
      "app.kubernetes.io/name" = "aws-load-balancer-controller"
    }
  }
}

provider "helm" {
  kubernetes {
    host = aws_eks_cluster.eks.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.eks.certificate_authority.0.data)
    exec {
      api_version = "client.authentication.k8s.io/v1alpha1"
      args        = ["eks", "get-token", "--cluster-name", var.cluster_name]
      command     = "aws"
    }
  }
}

resource "helm_release" "awslbc" {
  name = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace = "kube-system"
  depends_on = [
    kubernetes_service_account.aws_load_balancer_controller_sa,
    aws_eks_cluster.eks
  ]
  set {
    name = "region"
    value = data.aws_region.current
  }
  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }
  set {
    name = "clusterName"
    value = var.cluster_name
  }
  set {
    name  = "image.repository"
    value = "602401143452.dkr.ecr.eu-west-2.amazonaws.com/amazon/aws-load-balancer-controller"
  }
  set {
    name  = "serviceAccount.create"
    value = "false"
  }
  set {
    name = "enable-shield"
    value = "false"
  }
  set {
    name = "enable-waf"
    value = "false"
  }
  set {
    name = "enable-wafv2"
    value = "false"
  }
}