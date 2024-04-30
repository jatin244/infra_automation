provider "aws" {
  region = var.region
}

provider "aws" {
  alias = "ops"
  assume_role {
    role_arn = var.ops_assume_role_arn
  }
  region = var.region
}

provider "aws" {
  alias = "intercom"
  assume_role {
    role_arn = var.intercom_role_arn
  }
  region = var.region
}

provider "aws" {
  alias = "stack"
  assume_role {
    role_arn = var.stack_role_arn
  }
  region = var.region
}

data "aws_caller_identity" "stack" {
  provider = aws.stack
}

locals {

  stackCommon = {
    creds_profile                = var.creds_profile,
    stack_region                 = var.region,
    stack_name                   = var.environment,
    transit_gateway_id           = var.transit_gateway_id,
    transit_gateway_spoke_rtb_id = var.transit_gateway_spoke_rtb_id,
    transit_gateway_spoke_int_id = var.transit_gateway_spoke_int_id,
    egress_vpc_public_rtb_id     = var.egress_vpc_public_rtb_id,
    ingress_vpc_cidr             = var.ingress_vpc_cidr,
    ingress_vpc_public_rtb_id    = var.ingress_vpc_public_rtb_id,
    ingress_vpc_id               = var.ingress_vpc_id,
    ops_vpc_cidr                 = var.ops_vpc_cidr,
    ops_vpc_id                   = var.ops_vpc_id,
    ops_region                   = var.region,
    dns_vpc_id                   = var.dns_vpc_id,
    hosted_zone_name             = var.hosted_zone_name,
    common_tags = {
      environment = var.environment
      managedby   = var.managedby
      Environ     = var.environment
      Product     = var.product
    }
    extra_tags = {
      Environ = var.environment
      Product = var.product
    }
  }
}

data "aws_vpc" "data_vpc" {
  provider = aws.stack
  id       = var.data_vpc_enabled && (var.full_enabled || var.networking_enabled == true) ? join("", module.data-vpc.vpc.*.id) : var.data_vpc_id
}

data "aws_vpc" "application_vpc" {
  provider = aws.stack
  id       = var.application_vpc_enabled && (var.full_enabled || var.networking_enabled == true) ? join("", module.application-vpc.vpc.*.id) : var.application_vpc_id
}

data "aws_subnets" "data_public_subnet" {
  count    = var.data_vpc_enabled == false ? 1 : 0
  provider = aws.stack
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.data_vpc.id]
  }
  tags = {
    "public" = "1"
  }
}

data "aws_subnets" "data_private_subnet" {
  provider = aws.stack
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.data_vpc.id]
  }
  tags = {
    "private" = "1"
  }
}

data "aws_subnets" "application_public_subnet" {
  count    = var.application_vpc_enabled == false ? 1 : 0
  provider = aws.stack
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.application_vpc.id]
  }
  tags = {
    "public" = "1"
  }
}

data "aws_subnets" "application_private_subnet" {
  provider = aws.stack
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.application_vpc.id]
  }
  tags = {
    "private" = "1"
  }
}

#module "logs_s3_bucket" {
#  source = "../../../_modules/s3"
#  providers = {
#    aws.stack = aws.stack
#  }
#
#  name        = format("%s-logs-bucket", var.product)
#  environment = var.environment
#  attributes  = var.s3_attributes
#  label_order = var.label_order
#
#  create_bucket_enabled = var.s3_log_bucket_enabled && (var.full_enabled || var.networking_enabled == true)
#  force_destroy         = var.s3_force_destroy
#  versioning            = var.s3_versioning
#  acl                   = var.s3_acl
#  extra_tags            = local.stackCommon.extra_tags
#
#}

####################################################data-vpc############################################################
## VPC
module "data-vpc" {
  source          = "../../../_modules/vpc"
  environment     = var.environment
  enabled         = var.data_vpc_enabled && (var.full_enabled || var.networking_enabled == true)
  vpc_centralized = var.data_vpc_enabled
  providers = {
    aws.intercom = aws.intercom
    aws.stack    = aws.stack
  }
  base_infra = {
    vpc_name             = "data"
    vpc_cidr             = var.data_vpc_cidr
    private_route_tables = var.data_private_route_tables
    private_subnets      = merge(var.data_private_subnets, var.data_msk_private_subnets)
    eks_cluster_tag      = format("%s-eks-cluster", var.environment)
    EIPs                 = var.data_EIPs
    NATs                 = var.data_NATs
    public_route_tables  = var.data_public_route_tables
    public_subnets       = var.data_public_subnets
  }
  s3_bucket_arn = var.vpc_flow_log_s3
  stackCommon   = local.stackCommon
}

################################################application-vpc#########################################################
module "application-vpc" {
  source          = "../../../_modules/vpc"
  environment     = var.environment
  enabled         = var.application_vpc_enabled && (var.full_enabled || var.networking_enabled == true)
  vpc_centralized = var.application_vpc_enabled
  providers = {
    aws.intercom = aws.intercom
    aws.stack    = aws.stack
  }
  base_infra = {
    vpc_name             = "application"
    vpc_cidr             = var.application_vpc_cidr
    private_route_tables = var.application_private_route_tables
    private_subnets      = var.application_private_subnets
    eks_cluster_tag      = format("%s-eks-cluster", var.environment)
    EIPs                 = var.application_EIPs
    NATs                 = var.application_NATs
    public_route_tables  = var.application_public_route_tables
    public_subnets       = var.application_public_subnets
  }
  s3_bucket_arn       = var.vpc_flow_log_s3
  stackCommon         = local.stackCommon
  private_subnet_tags = var.application_private_subnet_tags
}


##############################################peering###################################################################
module "peering" {
  source      = "../../../_modules/vpc-peering"
  environment = var.environment
  providers = {
    aws.src = aws.stack
    aws.dst = aws.stack
  }
  aws_vpc_peering_connection_accepter_enabled = var.peering_enabled
  aws_vpc_peering_connection_enabled          = var.peering_enabled
  peering = var.peering_enabled && (var.full_enabled || var.networking_enabled == true) ? {
    peering_connection_name = var.peering_connection_name,
    different_account       = var.different_account,
    account_id              = var.peering_account_id,
    src_vpc_id              = data.aws_vpc.data_vpc.id,
    dst_vpc_id              = data.aws_vpc.application_vpc.id,
    } : {
    peering_connection_name = "",
    different_account       = false,
    account_id              = "",
    src_vpc_id              = "",
    dst_vpc_id              = "",
  }
  stackCommon = local.stackCommon
}

##########################################routing#######################################################################
module "routing" {
  source = "../../../_modules/routing"

  routing = var.peering_enabled && (var.full_enabled || var.networking_enabled == true) ? {
    src_rt_ids            = module.data-vpc.private_route_table_ids,
    dst_rt_ids            = module.application-vpc.private_route_table_ids,
    src_cidr              = var.data_vpc_cidr,
    dst_cidr              = var.application_vpc_cidr,
    peering_connection_id = var.peering_enabled == true && (var.full_enabled || var.networking_enabled == true) ? module.peering.peering_connection_ids : ""
    name                  = "data-application"
    } : {
    src_rt_ids            = [],
    dst_rt_ids            = [],
    src_cidr              = "",
    dst_cidr              = "",
    peering_connection_id = "",
    name                  = "data-application"
  }
  providers = {
    aws.src = aws.stack
    aws.dst = aws.stack
  }
}

module "route53_resolver_rule_association_data" {
  source = "../../../_modules/resolverrulevpcassociation"

  resolver_enabled = var.resolver_enabled && (var.full_enabled || var.networking_enabled == true)
  resolver_rule_id = var.route53_resolver_rule_id
  vpc              = var.data_vpc_enabled == false ? var.data_vpc_id : join("", data.aws_vpc.data_vpc.*.id)
  providers = {
    aws.stack = aws.stack
  }

}

module "route53_resolver_rule_association_application" {
  source = "../../../_modules/resolverrulevpcassociation"

  resolver_enabled = var.resolver_enabled && (var.full_enabled || var.networking_enabled == true)
  resolver_rule_id = var.route53_resolver_rule_id
  vpc              = var.application_vpc_enabled == false ? var.application_vpc_id : join("", data.aws_vpc.application_vpc.*.id)
  providers = {
    aws.stack = aws.stack
  }

}

#module "ingress_route53_association_application" {
#  source               = "../../../_modules/hostedzonevpcassociation"
#  route53_zone_enabled = var.application_vpc_route53_zone_enabled && (var.full_enabled || var.networking_enabled == true)
#  hostedzone           = var.hosted_zone_id
#  vpc                  = var.application_vpc_enabled == false ? var.application_vpc_id : join("", data.aws_vpc.application_vpc.*.id)
#  providers = {
#    aws.stack = aws.ops
#    aws.vpc   = aws.stack
#  }
#}

#module "ingress_route53_association_data" {
#  source = "../../../_modules/hostedzonevpcassociation"
#
#  route53_zone_enabled = var.data_vpc_route53_zone_enabled && (var.full_enabled || var.networking_enabled == true)
#  hostedzone           = var.hosted_zone_id
#  vpc                  = var.data_vpc_enabled == false ? var.data_vpc_id : join("", data.aws_vpc.data_vpc.*.id)
#  providers = {
#    aws.stack = aws.ops
#    aws.vpc   = aws.stack
#  }
#}
