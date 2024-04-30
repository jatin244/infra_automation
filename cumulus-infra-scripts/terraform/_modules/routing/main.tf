terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      configuration_aliases = [aws.src, aws.dst]
    }
  }
}

resource "aws_route" "source" {
  timeouts {
    create = "10m"
    delete = "10m"
  }
  provider = aws.src
  for_each = { for object in var.routing.src_rt_ids : object.name => object.id }

  route_table_id            = each.value
  destination_cidr_block    = var.routing.dst_cidr
  vpc_peering_connection_id = var.routing.peering_connection_id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route" "destination" {
  timeouts {
    create = "10m"
    delete = "10m"
  }
  provider = aws.dst
  for_each = { for object in var.routing.dst_rt_ids : object.name => object.id }

  route_table_id            = each.value
  destination_cidr_block    = var.routing.src_cidr
  vpc_peering_connection_id = var.routing.peering_connection_id

  lifecycle {
    create_before_destroy = true
  }
}
