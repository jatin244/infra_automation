# Setting providers for multi region resources
terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      configuration_aliases = [aws.src, aws.dst]
    }
  }
}

# Requester's side of the connection. OPS vpc is requester. When OPS VPC is in another region than stack.
resource "aws_vpc_peering_connection" "src_peering" {
  timeouts {
    create = "5m"
    delete = "5m"
  }
  count         = var.aws_vpc_peering_connection_enabled && var.peering_enabled ? 1 : 0
  provider      = aws.src
  peer_owner_id = var.peering.different_account ? var.peering.account_id : null
  vpc_id        = var.peering.src_vpc_id
  peer_vpc_id   = var.peering.dst_vpc_id
  peer_region   = var.stackCommon.stack_region
  auto_accept   = false

  tags = merge(
    tomap({
      "Name" = format("%s-%s", var.environment, var.peering.peering_connection_name)
    }),
    var.stackCommon.common_tags
  )

  lifecycle {
    create_before_destroy = true
  }
}
# Accepter's side of the connection.
resource "aws_vpc_peering_connection_accepter" "dst_peering" {
  count = var.aws_vpc_peering_connection_accepter_enabled && var.peering_enabled ? 1 : 0

  provider                  = aws.dst
  vpc_peering_connection_id = aws_vpc_peering_connection.src_peering[count.index].id
  auto_accept               = true

  tags = merge(
    tomap({
      "Name" = format("%s-%s", var.environment, var.peering.peering_connection_name)
    }),
    var.stackCommon.common_tags
  )

  lifecycle {
    create_before_destroy = true
  }
}

output "peering_connection_ids" {
  value = join("", aws_vpc_peering_connection.src_peering.*.id)
}
