terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      configuration_aliases = [aws.stack]
    }
  }
}

resource "aws_kms_key" "default" {
  provider                 = aws.stack
  count                    = var.kms_key_enabled ? 1 : 0
  deletion_window_in_days  = 7
  enable_key_rotation      = var.kms.enable_key_rotation
  policy                   = var.kms.policy
  tags                     = var.stackCommon.common_tags
  description              = var.kms.description
  key_usage                = var.kms.key_usage
  customer_master_key_spec = var.kms.customer_master_key_spec
  multi_region             = var.kms.multi_region
}

resource "aws_kms_alias" "default" {
  provider      = aws.stack
  count         = var.kms_key_enabled ? 1 : 0
  name          = var.alias
  target_key_id = join("", aws_kms_key.default.*.id)
}

output "key_id" {
  value       = join("", aws_kms_key.default.*.key_id)
  description = "Key ID."
}

output "key_arn" {
  value       = join("", aws_kms_key.default.*.arn)
  description = "Key ARN."
}