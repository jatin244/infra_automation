terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      configuration_aliases = [aws.stack]
    }
  }
}

resource "aws_route53_resolver_rule_association" "default" {
  count            = var.resolver_enabled ? length(var.resolver_rule_id) : 0
  provider         = aws.stack
  resolver_rule_id = var.resolver_rule_id[count.index]
  vpc_id           = var.vpc
}
