terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      configuration_aliases = [aws.stack]
    }
  }
}

module "labels" {
  source = "../labels"

  name        = var.name
  environment = var.environment
  managedby   = var.managedby
  label_order = var.label_order
}

resource "aws_iam_policy" "albingress" {
  count       = var.policy_enabled ? 1 : 0
  provider    = aws.stack
  name        = format("%s-policy", module.labels.id)
  description = format("Allow alb-ingress-controller to manage AWS resources")
  path        = "/"
  policy      = var.policy
}

resource "aws_iam_role_policy_attachment" "test-attach" {
  count      = var.policy_enabled ? 1 : 0
  provider   = aws.stack
  role       = var.role_name
  policy_arn = join("", aws_iam_policy.albingress.*.arn)
}