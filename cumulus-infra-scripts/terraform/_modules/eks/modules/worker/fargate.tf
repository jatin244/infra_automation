terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      configuration_aliases = [aws.stack]
      version               = ">= 3.1.15"
    }
  }
}

data "aws_vpc" "application_vpc" {
  provider = aws.stack
  tags = {
    Name = "${var.environment}-application" # Replace with your desired tag key-value pair
  }
}

data "aws_subnets" "application_private_subnet" {
  provider = aws.stack
  for_each = var.enabled && var.fargate_enabled ? var.fargate_profiles : {}
  filter {
    name   = "vpc-id"
    values = var.application_vpc_enabled == false ? [var.application_vpc_id] : data.aws_vpc.application_vpc.*.id
  }
  tags = {
    "private" = "1"
    "Component"    = "${each.value.subnet_component_tag}"
  }
}

#Module      : IAM ROLE
#Description : Provides an IAM role.
resource "aws_iam_role" "fargate_role" {
  count    = var.enabled && var.fargate_enabled ? 1 : 0
  provider = aws.stack

  name               = format("%s-fargate-role", module.labels.id)
  assume_role_policy = join("", data.aws_iam_policy_document.aws_eks_fargate_policy.*.json)
  tags               = module.labels.tags
}

resource "aws_iam_role_policy_attachment" "amazon_eks_fargate_pod_execution_role_policy" {
  count    = var.enabled && var.fargate_enabled ? 1 : 0
  provider = aws.stack

  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
  role       = join("", aws_iam_role.fargate_role.*.name)
}

#Module      : EKS Fargate
#Descirption : Enabling fargate for AWS EKS
resource "aws_eks_fargate_profile" "default" {
  for_each = var.enabled && var.fargate_enabled ? var.fargate_profiles : {}
  provider = aws.stack

  cluster_name           = var.cluster_name
  fargate_profile_name   = format("%s-fargate-%s", module.labels.id, each.value.addon_name)
  pod_execution_role_arn = aws_iam_role.fargate_role[0].arn
  subnet_ids             = data.aws_subnets.application_private_subnet[each.key].ids
  tags                   = module.labels.tags

  selector {
    namespace = lookup(each.value, "namespace", "default")
    labels    = lookup(each.value, "labels", null)
  }
}

# AWS EKS Fargate policy
data "aws_iam_policy_document" "aws_eks_fargate_policy" {
  count = var.enabled && var.fargate_enabled ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["eks-fargate-pods.amazonaws.com"]
    }
  }
}
