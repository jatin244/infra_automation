terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      configuration_aliases = [aws.stack, aws.intercom]
    }
  }
}

locals {
  vpc_name = format("%s-%s", var.environment, var.base_infra.vpc_name)
  tgw_attachment_selected_subnets = [for az in distinct([for s in aws_subnet.private_subnet : s.availability_zone]) : element([for s in aws_subnet.private_subnet : s.id if s.availability_zone == az], 0)]
}

##################################################
# VPC
##################################################
resource "aws_vpc" "vpc" {
  count                = var.enabled ? 1 : 0
  provider             = aws.stack
  cidr_block           = var.base_infra.vpc_cidr
  enable_dns_hostnames = true

  tags = merge(
    tomap({
      "Name" = local.vpc_name
    }),
    var.stackCommon.common_tags,
    var.vpc_tags
  )

  lifecycle {
    create_before_destroy = true
  }
}

##################################################
# Vpc Flow Log
##################################################
resource "aws_flow_log" "vpc_flow_log" {
  count                = var.enabled && var.enable_flow_log == true ? 1 : 0
  provider             = aws.stack
  log_destination      = var.s3_bucket_arn
  log_destination_type = "s3"
  traffic_type         = var.traffic_type
  vpc_id               = join("", aws_vpc.vpc.*.id)

}

output "vpc" {
  value = aws_vpc.vpc
}

##################################################
# Internet Gateway
##################################################
resource "aws_internet_gateway" "default" {
  count    = var.enabled && var.vpc_centralized == false ? 1 : 0
  provider = aws.stack
  vpc_id   = join("", aws_vpc.vpc.*.id)

  tags = merge(
    tomap({
      "Name" = format("%s-InternetGateway", local.vpc_name)
    }),
    var.stackCommon.common_tags,
    var.internet_gateway_tags
  )

  lifecycle {
    create_before_destroy = true
  }
}

##################################################
# Elastic IP(s)
##################################################
resource "aws_eip" "default" {
  provider = aws.stack
  for_each = var.enabled && var.vpc_centralized == false ? var.base_infra.EIPs : {}

  domain = "vpc"

  tags = merge(
    tomap({
      "Name" = format("%s-%s", var.environment, each.value.tagName)
    }),
    var.stackCommon.common_tags,
    var.eip_tags
  )

  lifecycle {
    create_before_destroy = true
  }
}

##################################################
# NAT Gateway(s)
##################################################
resource "aws_nat_gateway" "default" {
  provider = aws.stack
  for_each = var.enabled && var.vpc_centralized == false ? var.base_infra.NATs : {}

  allocation_id = each.value.elasticIP == null ? lookup(aws_eip.default, each.key).id : each.value.elasticIP
  subnet_id     = lookup(aws_subnet.public_subnet, each.value.public_subnet).id

  tags = merge(
    tomap({
      "Name"  = format("%s-%s", var.environment, each.value.tagName)
      "Group" = "NAT"
    }),
    var.stackCommon.common_tags,
    var.nat_gateway_tags
  )
  depends_on = [aws_eip.default, aws_vpc.vpc, aws_internet_gateway.default]

  lifecycle {
    create_before_destroy = true
  }
}

##################################################
# Public Subnet(s)
##################################################
resource "aws_subnet" "public_subnet" {
  provider = aws.stack
  for_each = var.enabled && var.vpc_centralized == false ? var.base_infra.public_subnets : {}

  vpc_id                  = aws_vpc.vpc.*.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az_name
  map_public_ip_on_launch = true

  tags = merge(
    tomap({
      "kubernetes.io/role/elb"                                  = each.value.eks_public_elb ? "1" : "0"
      "public"                                                  = "1"
      "Component"						= each.value.component
      "Name"                                                    = format("%s-%s-%s", var.environment, var.base_infra.vpc_name, each.key)
    }),
    var.stackCommon.common_tags,
    var.public_subnet_tags
  )

  lifecycle {
    create_before_destroy = true
  }
}

##################################################
# Private Subnet(s)
##################################################
resource "aws_subnet" "private_subnet" {
  provider = aws.stack
  for_each = var.enabled ? var.base_infra.private_subnets : {}

  vpc_id                  = join("", aws_vpc.vpc.*.id)
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az_name
  map_public_ip_on_launch = false

  tags = merge(
    tomap({
      "kubernetes.io/role/internal-elb"                         = each.value.eks_internal_elb ? "1" : "0"
      "private"                                                 = "1"
      "Component"						= each.value.component
      "Name"                                                    = format("%s-%s-%s", var.environment, var.base_infra.vpc_name, each.key)
    }),
    var.stackCommon.common_tags,
    var.private_subnet_tags
  )

  lifecycle {
    create_before_destroy = true
  }
}

output "private_subnet_id" {
  value = values(aws_subnet.private_subnet)[*].id
}
###############################################
#  Transit Gateway Attachment
###############################################

resource "aws_ec2_transit_gateway_vpc_attachment" "default_attachment" {
  count                                           = var.enabled ? 1 : 0
  provider                                        = aws.stack
  subnet_ids                                      = local.tgw_attachment_selected_subnets
#  subnet_ids                                      = [[for subnet in aws_subnet.private_subnet : subnet.id][0], [for subnet in aws_subnet.private_subnet : subnet.id][1]]
  transit_gateway_id                              = var.stackCommon.transit_gateway_id
  vpc_id                                          = join("", aws_vpc.vpc.*.id)
  transit_gateway_default_route_table_association = true
  transit_gateway_default_route_table_propagation = true
  tags = merge(
    tomap({
      "Name" = format("%s-%s", local.vpc_name, "att")
    }),
    var.stackCommon.common_tags,
    var.tgw_attachment_tags
  )

  lifecycle {
    create_before_destroy = true
  }
}

##################################################
# Public Route Table
##################################################
resource "aws_route_table" "public_route_table" {
  provider = aws.stack
  for_each = var.enabled && var.vpc_centralized == false ? var.base_infra.public_route_tables : {}

  vpc_id = aws_vpc.vpc.*.id

  tags = merge(
    tomap({
      "Name" = format("%s-%s-%s", var.environment, var.base_infra.vpc_name, each.value.tagName)
    }),
    var.stackCommon.common_tags,
    var.route_table_tags
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route" "internet_gateway_route" {
  provider = aws.stack
  timeouts {
    create = "10m"
    delete = "10m"
  }
  for_each = var.enabled && var.vpc_centralized == false ? var.base_infra.public_route_tables : {}

  route_table_id = lookup(aws_route_table.public_route_table, each.key).id
  gateway_id     = aws_internet_gateway.default.*.id

  destination_cidr_block = "0.0.0.0/0"

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [aws_route_table.public_route_table, aws_internet_gateway.default]
}


##################################################
# Private Route Table(s)
##################################################
resource "aws_route_table" "private_route_table" {
  provider = aws.stack
  for_each = var.enabled ? var.base_infra.private_route_tables : {}

  vpc_id = join("", aws_vpc.vpc.*.id)

  tags = merge(
    tomap({
      "Name"    = format("%s-%s-%s", var.environment, var.base_infra.vpc_name, each.value.tagName)
      "Private" = "yes"
    }),
    var.stackCommon.common_tags,
    var.route_table_tags
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route" "gateway_route" {
  provider = aws.stack
  timeouts {
    create = "10m"
    delete = "10m"
  }
  for_each = var.enabled && var.vpc_centralized == false ? var.base_infra.private_route_tables : {}

  route_table_id         = lookup(aws_route_table.private_route_table, each.key).id
  nat_gateway_id         = lookup(aws_nat_gateway.default, each.value.NAT).id
  destination_cidr_block = "0.0.0.0/0"

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [aws_route_table.private_route_table, aws_nat_gateway.default]
}

resource "aws_route" "transit_gateway_ops_route" {
  provider = aws.stack
  timeouts {
    create = "10m"
    delete = "10m"
  }
  for_each = var.enabled && var.vpc_centralized == false ? var.base_infra.private_route_tables : {}

  route_table_id         = lookup(aws_route_table.private_route_table, each.key).id
  transit_gateway_id     = var.stackCommon.transit_gateway_id
  destination_cidr_block = var.stackCommon.ops_vpc_cidr

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [aws_route_table.private_route_table, aws_nat_gateway.default]
}

################################################
# Private Subnet Routing
################################################
resource "aws_route" "transit_gateway_route" {
  provider = aws.stack
  timeouts {
    create = "10m"
    delete = "10m"
  }
  for_each = var.enabled ? var.base_infra.private_route_tables : {}

  route_table_id         = lookup(aws_route_table.private_route_table, each.key).id
  transit_gateway_id     = var.stackCommon.transit_gateway_id
  destination_cidr_block = "0.0.0.0/0"

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.default_attachment]
}

resource "aws_route" "transit_gateway_ingress_route" {
  provider = aws.stack
  timeouts {
    create = "10m"
    delete = "10m"
  }
  for_each = var.enabled && var.vpc_centralized == false ? var.base_infra.private_route_tables : {}

  route_table_id         = lookup(aws_route_table.private_route_table, each.key).id
  transit_gateway_id     = var.stackCommon.transit_gateway_id
  destination_cidr_block = var.stackCommon.ingress_vpc_cidr

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [aws_route_table.private_route_table, aws_nat_gateway.default]
}

output "private_route_tables" {
  value = aws_route_table.private_route_table
}

locals {
  rt_ids = flatten([
    for key, value in aws_route_table.private_route_table : {
      name = value.tags.Name
      id   = value.id
    }
  ])

  public_rt_ids = flatten([
    for key, value in aws_route_table.public_route_table : {
      name = value.tags.Name
      id   = value.id
    }
  ])
}

output "private_route_table_ids" {
  value = local.rt_ids
}

output "public_route_table_ids" {
  value = local.public_rt_ids
}

##################################################
# Public Route Table Associations
##################################################
resource "aws_route_table_association" "default_public" {
  provider = aws.stack
  for_each = var.enabled && var.vpc_centralized == false ? var.base_infra.public_subnets : {}

  subnet_id      = lookup(aws_subnet.public_subnet, each.key).id
  route_table_id = lookup(aws_route_table.public_route_table, each.value.route_table).id

  lifecycle {
    create_before_destroy = true
  }
}


##################################################
# Private Route Table Associations
##################################################
resource "aws_route_table_association" "default_private" {
  provider = aws.stack
  for_each = var.enabled ? var.base_infra.private_subnets : {}

  subnet_id      = lookup(aws_subnet.private_subnet, each.key).id
  route_table_id = lookup(aws_route_table.private_route_table, each.value.route_table).id

  lifecycle {
    create_before_destroy = true
  }
}

################################################
# Egress VPC Public Routing
################################################
resource "aws_route" "egress_vpc_public_route" {
  count = var.enabled && var.vpc_centralized ? 1 : 0
  timeouts {
    create = "10m"
    delete = "10m"
  }
  provider               = aws.intercom
  route_table_id         = var.stackCommon.egress_vpc_public_rtb_id
  transit_gateway_id     = var.stackCommon.transit_gateway_id
  destination_cidr_block = var.base_infra.vpc_cidr

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.default_attachment]
}

################################################
# Ingress VPC Public Routing
################################################
resource "aws_route" "ingress_vpc_public_route" {
  count = var.enabled ? 1 : 0
  timeouts {
    create = "10m"
    delete = "10m"
  }
  provider               = aws.intercom
  route_table_id         = var.stackCommon.ingress_vpc_public_rtb_id
  transit_gateway_id     = var.stackCommon.transit_gateway_id
  destination_cidr_block = var.base_infra.vpc_cidr

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.default_attachment]
}

################################################
# Transit Gateway INT Route
################################################
resource "aws_ec2_transit_gateway_route" "tgw_int_route" {
  count                          = var.enabled && var.vpc_centralized ? 1 : 0
  provider                       = aws.intercom
  destination_cidr_block         = var.base_infra.vpc_cidr
  transit_gateway_attachment_id  = join("", aws_ec2_transit_gateway_vpc_attachment.default_attachment.*.id)
  transit_gateway_route_table_id = var.stackCommon.transit_gateway_spoke_int_id

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.default_attachment]
}

################################################
# Transit Gateway Attachment Tagging in Intercom Account
################################################
resource "aws_ec2_tag" "tgw_attachment_tag" {
  count       = var.enabled ? 1 : 0
  provider    = aws.intercom
  resource_id = join("", aws_ec2_transit_gateway_vpc_attachment.default_attachment.*.id)
  key         = "Name"
  value       = format("%s-%s", local.vpc_name, "att")

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.default_attachment]
}
