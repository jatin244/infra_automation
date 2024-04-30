terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      configuration_aliases = [aws.stack]
    }
  }
}

resource "aws_security_group" "default" {
  provider   = aws.stack
  depends_on = [var.depends]
  for_each   = var.security_enabled ? { for o in var.SGs : o.name => o } : {}

  name                   = format("%s-%s", var.environment, each.value.name)
  description            = each.value.description
  vpc_id                 = try(lookup(var.base_info, each.value.vpc).vpc_id, each.value.vpc)
  revoke_rules_on_delete = true

  tags = merge(
    tomap({
      "Name" = format("%s-%s", var.environment, each.value.name)
    }),
    var.stackCommon.common_tags
  )

  lifecycle {
    create_before_destroy = true
  }
}

output "sgs" {
  value = aws_security_group.default
}

output "id" {
  value = values(aws_security_group.default)[*].id
}

resource "aws_security_group_rule" "default" {
  provider   = aws.stack
  depends_on = [var.depends]
  # need unique key for resource state obj's
  # may need to assign a unique id field to the list obj's
  for_each = var.security_enabled ? { for o in var.SG_Rules : format("%s-%s-%v-%v-%s-%s-%s", o.type, o.security_group_name, o.source_security_group_name, o.cidr_blocks, o.from_port, o.to_port, o.description) => o } : {}

  security_group_id        = try(var.SG_id_map[each.value.security_group_name], aws_security_group.default[each.value.security_group_name].id)
  source_security_group_id = each.value.source_security_group_name != null ? try(var.SG_id_map[each.value.source_security_group_name], aws_security_group.default[each.value.source_security_group_name].id) : each.value.source_security_group_id
  type                     = each.value.type
  from_port                = each.value.from_port
  to_port                  = each.value.to_port
  protocol                 = each.value.protocol
  cidr_blocks              = each.value.cidr_blocks
  prefix_list_ids          = each.value.prefix_list_ids
  description              = each.value.description
  self                     = each.value.self != null ? each.value.self : null

  lifecycle {
    create_before_destroy = true
  }
}
