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
  extra_tags  = var.extra_tags
}

resource "aws_route53_record" "default" {
  count                            = var.record_enabled && length(var.alias) == 0 ? 1 : 0
  provider                         = aws.stack
  zone_id                          = var.zone_id
  name                             = var.name
  type                             = var.type
  ttl                              = var.ttl
  records                          = split(",", var.values)
  set_identifier                   = var.set_identifier
  health_check_id                  = var.health_check_id
  multivalue_answer_routing_policy = var.multivalue_answer_routing_policy
  allow_overwrite                  = var.allow_overwrite
}

# Module      : Route53 Record Set
# Description : Terraform module to create Route53 record sets resource on AWS.
resource "aws_route53_record" "alias" {
  count                            = var.record_enabled && length(var.alias) > 0 ? 1 : 0
  provider                         = aws.stack
  zone_id                          = var.zone_id
  name                             = var.name
  type                             = var.type
  set_identifier                   = var.set_identifier
  health_check_id                  = var.health_check_id
  multivalue_answer_routing_policy = var.multivalue_answer_routing_policy
  allow_overwrite                  = var.allow_overwrite
  alias {
    name                   = var.alias["name"]
    zone_id                = var.alias["zone_id"]
    evaluate_target_health = var.alias["evaluate_target_health"]
  }
}
