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
  count    = var.data_vpc_enabled == true ? 1 : 0
  provider = aws.stack
  tags = {
    Name = "${var.environment}-data" # Replace with your desired tag key-value pair
  }
}

data "aws_vpc" "application_vpc" {
  count    = var.application_vpc_enabled == true ? 1 : 0
  provider = aws.stack
  tags = {
    Name = "${var.environment}-application" # Replace with your desired tag key-value pair
  }
}

data "aws_subnets" "data_public_subnet" {
  count    = var.data_vpc_enabled == false ? 1 : 0
  provider = aws.stack
  filter {
    name   = "vpc-id"
    values = var.data_vpc_enabled == false ? [var.data_vpc_id] : data.aws_vpc.data_vpc.*.id
  }
  tags = {
    "public" = "1"
  }
}

data "aws_subnets" "data_private_subnet" {
  provider = aws.stack
  filter {
    name   = "vpc-id"
    values = var.data_vpc_enabled == false ? [var.data_vpc_id] : data.aws_vpc.data_vpc.*.id
  }
  tags = {
    "private" = "1"
    "Component" = "shared-data"
  }
}

data "aws_subnets" "msk_private_subnet" {
  provider = aws.stack
  filter {
    name   = "vpc-id"
    values = var.data_vpc_enabled == false ? [var.data_vpc_id] : data.aws_vpc.data_vpc.*.id
  }
  tags = {
    "private" = "1"
    "Component" = "kafka"
  }
}

data "aws_subnets" "application_public_subnet" {
  count    = var.application_vpc_enabled == false ? 1 : 0
  provider = aws.stack
  filter {
    name   = "vpc-id"
    values = var.application_vpc_enabled == false ? [var.application_vpc_id] : data.aws_vpc.application_vpc.*.id
  }
  tags = {
    "public" = "1"
  }
}

data "aws_subnets" "application_private_subnet" {
  provider = aws.stack
  filter {
    name   = "vpc-id"
    values = var.application_vpc_enabled == false ? [var.application_vpc_id] : data.aws_vpc.application_vpc.*.id
  }
  tags = {
    "private" = "1"
  }
}

data "aws_subnets" "eks_private_subnet" {
  provider = aws.stack
  filter {
    name   = "vpc-id"
    values = var.application_vpc_enabled == false ? [var.application_vpc_id] : data.aws_vpc.application_vpc.*.id
  }
  tags = {
    "private" = "1"
    "Component" = "eks-mgmt"
  }
}

#########################################secret manager#################################################################
module "secrets_manager" {
  source = "../../../_modules/secrets-manager"
  providers = {
    aws.stack = aws.stack
  }
  name        = "secrets"
  environment = var.environment
  label_order = var.label_order

  secrets = var.secrets_enabled && (var.full_enabled || var.networking_enabled == false) ? [
    {
      name = format("%s-DATABASE_DETAILS", var.environment)
      secret_key_value = {
        DB_HOST     = module.mysql.db_instance_endpoint
        DB_DATABASE = var.mysql_database_name
        DB_USERNAME = var.mysql_username
        DB_PASSWORD = module.mysql.db_instance_password
      }
      recovery_window_in_days = var.recovery_window_in_days
    }
  ] : []
}

##########################################################ssh_sg########################################################
module "security-groups" {
  source = "../../../_modules/security-group"
  providers = {
    aws.stack = aws.stack
  }
  environment      = var.environment
  security_enabled = var.security_enabled && (var.full_enabled || var.networking_enabled == false) ? true : false
  SGs = [
    {
      name        = var.ssh_sg_name,
      description = "Security group used for ssh in data vpc ec2",
      vpc         = var.data_vpc_enabled == false ? var.data_vpc_id : join("", data.aws_vpc.data_vpc.*.id),
    },
    {
      name        = var.redis_sg_name,
      description = "Security group used for redis connectivity",
      vpc         = var.data_vpc_enabled == false ? var.data_vpc_id : join("", data.aws_vpc.data_vpc.*.id),
    },
    {
      name        = var.secure_redis_sg_name,
      description = "Security group used for secure redis connectivity",
      vpc         = var.data_vpc_enabled == false ? var.data_vpc_id : join("", data.aws_vpc.data_vpc.*.id),
    },
    {
      name        = var.mysql_sg_name,
      description = "Security group used for RDS",
      vpc         = var.data_vpc_enabled == false ? var.data_vpc_id : join("", data.aws_vpc.data_vpc.*.id),
    },
    {
      name        = var.msk_sg_name,
      description = "Security group used for MSK",
      vpc         = var.data_vpc_enabled == false ? var.data_vpc_id : join("", data.aws_vpc.data_vpc.*.id),
    },
    {
      name        = var.etcd_ec2_sg_name,
      description = "Security group used for etcd EC2",
      vpc         = var.data_vpc_enabled == false ? var.data_vpc_id : join("", data.aws_vpc.data_vpc.*.id),
    },
    {
      name        = var.es_ec2_sg_name,
      description = "Security group used for ES ec2",
      vpc         = var.data_vpc_enabled == false ? var.data_vpc_id : join("", data.aws_vpc.data_vpc.*.id),
    },
    {
      name        = var.es_nlb_sg_name,
      description = "Security group used for ES NLB",
      vpc         = var.data_vpc_enabled == false ? var.data_vpc_id : join("", data.aws_vpc.data_vpc.*.id),
    }
  ]
  stackCommon = local.stackCommon

  SG_Rules = [
       {    
      type                       = var.ssh_sg_type,
      security_group_name        = var.ssh_sg_name,
      source_security_group_name = var.ssh_sg_source_security_group_name,
      source_security_group_id   = var.ssh_sg_source_security_group_id,
      from_port                  = var.ssh_sg_from_port,
      to_port                    = var.ssh_sg_to_port,
      protocol                   = var.ssh_sg_protocol,
      cidr_blocks                = var.ssh_sg_cidr_blocks,
      prefix_list_ids            = var.ssh_sg_prefix_list_ids
      description                = "User Input",
      self                       = var.ssh_sg_self
    },
    {
      type                       = var.egress_type,
      security_group_name        = var.ssh_sg_name,
      source_security_group_name = var.ssh_sg_source_security_group_name,
      source_security_group_id   = var.ssh_sg_source_security_group_id,
      from_port                  = 0,
      to_port                    = 0,
      protocol                   = -1,
      cidr_blocks                = var.egress_allow_cidr_blocks,
      prefix_list_ids            = var.ssh_sg_prefix_list_ids
      description                = "All allow",
      self                       = var.ssh_sg_self
    },
    {
      type                       = var.redis_sg_type,
      security_group_name        = var.redis_sg_name,
      source_security_group_name = var.redis_sg_source_security_group_name,
      source_security_group_id   = var.redis_sg_source_security_group_id,
      from_port                  = var.redis_sg_from_port,
      to_port                    = var.redis_sg_to_port,
      protocol                   = var.redis_sg_protocol,
      cidr_blocks                = split(",", var.application_vpc_cidr)
      prefix_list_ids            = var.redis_sg_prefix_list_ids
      description                = "Application VPC",
      self                       = var.redis_sg_self,
    },
    {
      type                       = var.redis_sg_type,
      security_group_name        = var.redis_sg_name,
      source_security_group_name = var.redis_sg_source_security_group_name,
      source_security_group_id   = var.redis_sg_source_security_group_id,
      from_port                  = var.redis_sg_from_port,
      to_port                    = var.redis_sg_to_port,
      protocol                   = var.redis_sg_protocol,
      cidr_blocks                = var.redis_sg_cidr_blocks
      prefix_list_ids            = var.redis_sg_prefix_list_ids
      description                = "User Input",
      self                       = var.redis_sg_self,
    },
#    {
#      type                       = var.egress_type,
#      security_group_name        = var.redis_sg_name,
#      source_security_group_name = var.redis_sg_source_security_group_name,
#      source_security_group_id   = var.redis_sg_source_security_group_id,
#      from_port                  = 0,
#      to_port                    = 0,
#      protocol                   = -1,
#      cidr_blocks                = var.egress_allow_cidr_blocks,
#      prefix_list_ids            = var.redis_sg_prefix_list_ids
#      description                = "All allow",
#      self                       = var.redis_sg_self
#    },
    {
      type                       = var.secure_redis_sg_type,
      security_group_name        = var.secure_redis_sg_name,
      source_security_group_name = var.secure_redis_sg_source_security_group_name,
      source_security_group_id   = var.secure_redis_sg_source_security_group_id,
      from_port                  = var.secure_redis_sg_from_port,
      to_port                    = var.secure_redis_sg_to_port,
      protocol                   = var.secure_redis_sg_protocol,
      cidr_blocks                = split(",", var.application_vpc_cidr)
      prefix_list_ids            = var.secure_redis_sg_prefix_list_ids
      description                = "Application VPC",
      self                       = var.secure_redis_sg_self,
    },
    {
      type                       = var.secure_redis_sg_type,
      security_group_name        = var.secure_redis_sg_name,
      source_security_group_name = var.secure_redis_sg_source_security_group_name,
      source_security_group_id   = var.secure_redis_sg_source_security_group_id,
      from_port                  = var.secure_redis_sg_from_port,
      to_port                    = var.secure_redis_sg_to_port,
      protocol                   = var.secure_redis_sg_protocol,
      cidr_blocks                = var.secure_redis_sg_cidr_blocks
      prefix_list_ids            = var.secure_redis_sg_prefix_list_ids
      description                = "User Input",
      self                       = var.secure_redis_sg_self,
    },
#    {
#      type                       = var.egress_type,
#      security_group_name        = var.secure_redis_sg_name,
#      source_security_group_name = var.secure_redis_sg_source_security_group_name,
#      source_security_group_id   = var.secure_redis_sg_source_security_group_id,
#      from_port                  = 0,
#      to_port                    = 0,
#      protocol                   = -1,
#      cidr_blocks                = var.egress_allow_cidr_blocks,
#      prefix_list_ids            = var.secure_redis_sg_prefix_list_ids
#      description                = "All allow",
#      self                       = var.secure_redis_sg_self
#    },
    {
      type                       = var.mysql_sg_type,
      security_group_name        = var.mysql_sg_name,
      source_security_group_name = var.mysql_sg_source_security_group_name,
      source_security_group_id   = var.mysql_sg_source_security_group_id,
      from_port                  = var.mysql_sg_from_port,
      to_port                    = var.mysql_sg_to_port,
      protocol                   = var.mysql_sg_protocol,
      cidr_blocks                = var.mysql_sg_cidr_blocks
      prefix_list_ids            = var.mysql_sg_prefix_list_ids
      description                = "User Input ",
      self                       = var.mysql_sg_self,
    },
    {
      type                       = var.mysql_sg_type,
      security_group_name        = var.mysql_sg_name,
      source_security_group_name = var.mysql_sg_source_security_group_name,
      source_security_group_id   = var.mysql_sg_source_security_group_id,
      from_port                  = var.mysql_sg_from_port,
      to_port                    = var.mysql_sg_to_port,
      protocol                   = var.mysql_sg_protocol,
      cidr_blocks                = split(",", var.application_vpc_cidr)
      prefix_list_ids            = var.mysql_sg_prefix_list_ids
      description                = "Application VPC ",
      self                       = var.mysql_sg_self,
    },
#    {
#      type                       = var.egress_type,
#      security_group_name        = var.mysql_sg_name,
#      source_security_group_name = var.mysql_sg_source_security_group_name,
#      source_security_group_id   = var.mysql_sg_source_security_group_id,
#      from_port                  = 0,
#      to_port                    = 0,
#      protocol                   = -1,
#      cidr_blocks                = var.egress_allow_cidr_blocks,
#      prefix_list_ids            = var.mysql_sg_prefix_list_ids
#      description                = "All allow",
#      self                       = var.mysql_sg_self
#    },
    {
      type                       = var.msk_sg_type,
      security_group_name        = var.msk_sg_name,
      source_security_group_name = var.msk_sg_source_security_group_name,
      source_security_group_id   = var.msk_sg_source_security_group_id,
      from_port                  = var.msk_sg_from_port,
      to_port                    = var.msk_sg_to_port,
      protocol                   = var.msk_sg_protocol,
      cidr_blocks                = split(",", var.application_vpc_cidr)
      prefix_list_ids            = var.msk_sg_prefix_list_ids
      description                = "Application VPC",
      self                       = var.msk_sg_self
    },
        {
      type                       = var.msk_sg_type,
      security_group_name        = var.msk_sg_name,
      source_security_group_name = var.msk_sg_source_security_group_name,
      source_security_group_id   = var.msk_sg_source_security_group_id,
      from_port                  = var.msk_sg_from_port,
      to_port                    = var.msk_sg_to_port,
      protocol                   = var.msk_sg_protocol,
      cidr_blocks                = var.msk_sg_cidr_blocks
      prefix_list_ids            = var.msk_sg_prefix_list_ids
      description                = "User Input",
      self                       = var.msk_sg_self
    },
    {
      type                       = var.msk_sg_type,
      security_group_name        = var.msk_sg_name,
      source_security_group_name = var.msk_sg_source_security_group_name,
      source_security_group_id   = var.msk_sg_source_security_group_id,
      from_port                  = 9092,
      to_port                    = 9092,
      protocol                   = var.msk_sg_protocol,
      cidr_blocks                = split(",", var.application_vpc_cidr)
      prefix_list_ids            = var.msk_sg_prefix_list_ids
      description                = "Application VPC",
      self                       = var.msk_sg_self
    },
    {
      type                       = var.msk_sg_type,
      security_group_name        = var.msk_sg_name,
      source_security_group_name = var.msk_sg_source_security_group_name,
      source_security_group_id   = var.msk_sg_source_security_group_id,
      from_port                  = 9092,
      to_port                    = 9092,
      protocol                   = var.msk_sg_protocol,
      cidr_blocks                = var.msk_sg_cidr_blocks
      prefix_list_ids            = var.msk_sg_prefix_list_ids
      description                = "User Input",
      self                       = var.msk_sg_self
    },
#    {
#      type                       = var.egress_type,
#      security_group_name        = var.msk_sg_name,
#      source_security_group_name = var.msk_sg_source_security_group_name,
#      source_security_group_id   = var.msk_sg_source_security_group_id,
#      from_port                  = 0,
#      to_port                    = 0,
#      protocol                   = -1,
#      cidr_blocks                = var.egress_allow_cidr_blocks,
#      prefix_list_ids            = var.msk_sg_prefix_list_ids
#      description                = "All allow",
#      self                       = var.msk_sg_self
#    },
    {
      type                       = var.etcd_ec2_sg_type,
      security_group_name        = var.etcd_ec2_sg_name,
      source_security_group_name = var.etcd_ec2_sg_source_security_group_name,
      source_security_group_id   = var.etcd_ec2_sg_source_security_group_id,
      from_port                  = 2379,
      to_port                    = 2379,
      protocol                   = var.etcd_ec2_sg_protocol,
      cidr_blocks                = split(",", var.application_vpc_cidr)
      prefix_list_ids            = var.etcd_ec2_sg_prefix_list_ids
      description                = "Application VPC",
      self                       = var.etcd_ec2_sg_self
    },
    {
      type                       = var.etcd_ec2_sg_type,
      security_group_name        = var.etcd_ec2_sg_name,
      source_security_group_name = var.etcd_ec2_sg_source_security_group_name,
      source_security_group_id   = var.etcd_ec2_sg_source_security_group_id,
      from_port                  = 2379,
      to_port                    = 2379,
      protocol                   = var.etcd_ec2_sg_protocol,
      cidr_blocks                = var.etcd_ec2_sg_cidr_blocks
      prefix_list_ids            = var.etcd_ec2_sg_prefix_list_ids
      description                = "User Input",
      self                       = var.etcd_ec2_sg_self
    },
    {
      type                       = var.etcd_ec2_sg_type,
      security_group_name        = var.etcd_ec2_sg_name,
      source_security_group_name = var.etcd_ec2_sg_source_security_group_name,
      source_security_group_id   = module.security-groups.sgs.etcd-ec2-sg.id,
      from_port                  = 2380,
      to_port                    = 2380,
      protocol                   = var.etcd_ec2_sg_protocol,
      cidr_blocks                = null
      prefix_list_ids            = null
      description                = "Self Peer",
      self                       = null
    },

    {
      type                       = var.egress_type,
      security_group_name        = var.etcd_ec2_sg_name,
      source_security_group_name = var.etcd_ec2_sg_source_security_group_name,
      source_security_group_id   = var.etcd_ec2_sg_source_security_group_id,
      from_port                  = 0,
      to_port                    = 0,
      protocol                   = -1,
      cidr_blocks                = var.egress_allow_cidr_blocks,
      prefix_list_ids            = var.etcd_ec2_sg_prefix_list_ids
      description                = "All allow",
      self                       = var.etcd_ec2_sg_self
    },
    {
      type                       = var.es_ec2_sg_type,
      security_group_name        = var.es_ec2_sg_name,
      source_security_group_name = var.es_ec2_sg_source_security_group_name,
      source_security_group_id   = var.es_ec2_sg_source_security_group_id,
      from_port                  = 9200,
      to_port                    = 9200,
      protocol                   = var.es_ec2_sg_protocol,
      cidr_blocks                = split(",", var.application_vpc_cidr)
      prefix_list_ids            = var.es_ec2_sg_prefix_list_ids
      description                = "Application VPC",
      self                       = var.es_ec2_sg_self
    },
    {
      type                       = var.es_ec2_sg_type,
      security_group_name        = var.es_ec2_sg_name,
      source_security_group_name = var.es_ec2_sg_source_security_group_name,
      source_security_group_id   = var.es_ec2_sg_source_security_group_id,
      from_port                  = 9200,
      to_port                    = 9200,
      protocol                   = var.es_ec2_sg_protocol,
      cidr_blocks                = var.es_ec2_sg_cidr_blocks
      prefix_list_ids            = var.es_ec2_sg_prefix_list_ids
      description                = "User Input",
      self                       = var.es_ec2_sg_self
    },
    {
      type                       = var.es_ec2_sg_type,
      security_group_name        = var.es_ec2_sg_name,
      source_security_group_name = var.es_ec2_sg_source_security_group_name,
      source_security_group_id   = var.es_ec2_sg_source_security_group_id,
      from_port                  = 443,
      to_port                    = 443,
      protocol                   = var.es_ec2_sg_protocol,
      cidr_blocks                = split(",", var.application_vpc_cidr)
      prefix_list_ids            = var.es_ec2_sg_prefix_list_ids
      description                = "Application VPC",
      self                       = var.es_ec2_sg_self
    },
    {
      type                       = var.es_ec2_sg_type,
      security_group_name        = var.es_ec2_sg_name,
      source_security_group_name = var.es_ec2_sg_source_security_group_name,
      source_security_group_id   = var.es_ec2_sg_source_security_group_id,
      from_port                  = 443,
      to_port                    = 443,
      protocol                   = var.es_ec2_sg_protocol,
      cidr_blocks                = var.etcd_ec2_sg_cidr_blocks
      prefix_list_ids            = var.es_ec2_sg_prefix_list_ids
      description                = "User Input",
      self                       = var.es_ec2_sg_self
    },
    {
      type                       = var.egress_type,
      security_group_name        = var.es_ec2_sg_name,
      source_security_group_name = var.es_ec2_sg_source_security_group_name,
      source_security_group_id   = var.es_ec2_sg_source_security_group_id,
      from_port                  = 0,
      to_port                    = 0,
      protocol                   = -1,
      cidr_blocks                = var.egress_allow_cidr_blocks,
      prefix_list_ids            = var.es_ec2_sg_prefix_list_ids
      description                = "All allow",
      self                       = var.es_ec2_sg_self
    },
    {
      type                       = var.es_nlb_sg_type,
      security_group_name        = var.es_nlb_sg_name,
      source_security_group_name = var.es_nlb_sg_source_security_group_name,
      source_security_group_id   = var.es_nlb_sg_source_security_group_id,
      from_port                  = 9200,
      to_port                    = 9200,
      protocol                   = var.es_nlb_sg_protocol,
      cidr_blocks                = split(",", var.application_vpc_cidr)
      prefix_list_ids            = var.es_nlb_sg_prefix_list_ids
      description                = "Application VPC",
      self                       = var.es_nlb_sg_self
    },
    {
      type                       = var.es_nlb_sg_type,
      security_group_name        = var.es_nlb_sg_name,
      source_security_group_name = var.es_nlb_sg_source_security_group_name,
      source_security_group_id   = var.es_nlb_sg_source_security_group_id,
      from_port                  = 9200,
      to_port                    = 9200,
      protocol                   = var.es_nlb_sg_protocol,
      cidr_blocks                = var.es_nlb_sg_cidr_blocks
      prefix_list_ids            = var.es_nlb_sg_prefix_list_ids
      description                = "User Input",
      self                       = var.es_nlb_sg_self
    },
    {
      type                       = var.es_nlb_sg_type,
      security_group_name        = var.es_nlb_sg_name,
      source_security_group_name = var.es_nlb_sg_source_security_group_name,
      source_security_group_id   = var.es_nlb_sg_source_security_group_id,
      from_port                  = 443,
      to_port                    = 443,
      protocol                   = var.es_nlb_sg_protocol,
      cidr_blocks                = split(",", var.application_vpc_cidr)
      prefix_list_ids            = var.es_nlb_sg_prefix_list_ids
      description                = "Application VPC",
      self                       = var.es_nlb_sg_self
    },
    {
      type                       = var.es_nlb_sg_type,
      security_group_name        = var.es_nlb_sg_name,
      source_security_group_name = var.es_nlb_sg_source_security_group_name,
      source_security_group_id   = var.es_nlb_sg_source_security_group_id,
      from_port                  = 443,
      to_port                    = 443,
      protocol                   = var.es_nlb_sg_protocol,
      cidr_blocks                = var.es_nlb_sg_cidr_blocks
      prefix_list_ids            = var.es_nlb_sg_prefix_list_ids
      description                = "User Input",
      self                       = var.es_nlb_sg_self
    },
    {
      type                       = var.egress_type,
      security_group_name        = var.es_nlb_sg_name,
      source_security_group_name = var.es_ec2_sg_name,
      source_security_group_id   = null
      from_port                  = 9200,
      to_port                    = 9200,
      protocol                   = "tcp"
      cidr_blocks                = null
      prefix_list_ids            = null
      description                = "NLB to EC2",
      self                       = var.es_nlb_sg_self
    },
    {
      type                       = var.egress_type,
      security_group_name        = var.es_nlb_sg_name,
      source_security_group_name = var.es_ec2_sg_name,
      source_security_group_id   = null
      from_port                  = 443,
      to_port                    = 443,
      protocol                   = "tcp"
      cidr_blocks                = null
      prefix_list_ids            = null
      description                = "NLB to EC@",
      self                       = var.es_nlb_sg_self
    },

  ]
  base_info = {}
}
#######################################################kms_rds##########################################################
module "kms_rds" {
  source = "../../../_modules/kms"

  providers = {
    aws.stack = aws.stack
  }
  kms_key_enabled = var.mysql_enabled && (var.full_enabled || var.networking_enabled == false)
  kms = {
    description              = var.kms_description,
    key_usage                = var.key_usage,
    customer_master_key_spec = var.customer_master_key_spec,
    policy                   = data.aws_iam_policy_document.default.json,
    enable_key_rotation      = var.enable_key_rotation,
    multi_region             = var.multi_region,
  }
  stackCommon = local.stackCommon
  alias       = format("alias/%s-rds", var.environment)
}

data "aws_iam_policy_document" "default" {
  version   = "2012-10-17"
  policy_id = "rds-encryption"
  statement {
    sid    = "Allow access through RDS for all principals in the account that are authorized to use RDS"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:CreateGrant",
      "kms:ListGrants",
      "kms:DescribeKey"
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "kms:CallerAccount"
      values   = [data.aws_caller_identity.stack.account_id]
    }
    condition {
      test     = "StringLike"
      variable = "kms:ViaService"
      values   = ["rds.*.amazonaws.com"]
    }
  }
  statement {
    sid    = "Allow direct access to key metadata to the account"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [format("arn:aws:iam::%s:root", data.aws_caller_identity.stack.account_id)]
    }
    actions   = ["*"]
    resources = ["*"]
  }
}
##############################################kms_kafka#################################################################
module "kms_kafka" {
  source = "../../../_modules/kms"

  providers = {
    aws.stack = aws.stack
  }
  kms_key_enabled = var.msk_cluster_enabled && (var.full_enabled || var.networking_enabled == false)
  kms = {
    description              = var.kafka_kms_description,
    key_usage                = var.kafka_key_usage,
    customer_master_key_spec = var.kafka_customer_master_key_spec,
    policy                   = data.aws_iam_policy_document.kafka.json,
    enable_key_rotation      = var.kafka_enable_key_rotation,
    multi_region             = var.kafka_multi_region,
  }
  stackCommon = local.stackCommon
  alias       = format("alias/%s-kafka", var.environment)
}

data "aws_iam_policy_document" "kafka" {
  version   = "2012-10-17"
  policy_id = "kafka-encryption"
  statement {
    sid    = "Allow access through kafka for all principals in the account that are authorized to use kafka"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:CreateGrant",
      "kms:ListGrants",
      "kms:DescribeKey"
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "kms:CallerAccount"
      values   = [data.aws_caller_identity.stack.account_id]
    }
    condition {
      test     = "StringLike"
      variable = "kms:ViaService"
      values   = ["kafka.*.amazonaws.com"]
    }
  }
  statement {
    sid    = "Allow direct access to key metadata to the account"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [format("arn:aws:iam::%s:root", data.aws_caller_identity.stack.account_id)]
    }
    actions   = ["*"]
    resources = ["*"]
  }
}

###################################################kms_redis############################################################
module "kms_redis" {
  source = "../../../_modules/kms"

  providers = {
    aws.stack = aws.stack
  }
  kms_key_enabled = var.redis_cluster_enabled && (var.full_enabled || var.networking_enabled == false)
  kms = {
    description              = var.redis_kms_description,
    key_usage                = var.redis_key_usage,
    customer_master_key_spec = var.redis_customer_master_key_spec,
    policy                   = data.aws_iam_policy_document.redis.json,
    enable_key_rotation      = var.redis_enable_key_rotation,
    multi_region             = var.kms_redis_multi_region,
  }
  stackCommon = local.stackCommon
  alias       = format("alias/%s-redis", var.environment)
}

data "aws_iam_policy_document" "redis" {
  version   = "2012-10-17"
  policy_id = "rds-encryption"
  statement {
    sid    = "Allow access through RDS for all principals in the account that are authorized to use RDS"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:CreateGrant",
      "kms:ListGrants",
      "kms:DescribeKey"
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "kms:CallerAccount"
      values   = [data.aws_caller_identity.stack.account_id]
    }
    condition {
      test     = "StringLike"
      variable = "kms:ViaService"
      values   = ["rds.*.amazonaws.com"]
    }
  }
  statement {
    sid    = "Allow direct access to key metadata to the account"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [format("arn:aws:iam::%s:root", data.aws_caller_identity.stack.account_id)]
    }
    actions   = ["*"]
    resources = ["*"]
  }
}

module "redis-cluster" {
  source = "../../../_modules/elasticache"

  providers = {
    aws.stack = aws.stack
  }
  name        = "redis-cluster"
  environment = var.environment
  label_order = var.label_order

  enable_elasticache_cluster = var.redis_cluster_enabled && (var.full_enabled || var.networking_enabled == false)

  replication_enabled        = true
  number_cache_clusters      = 2
  engine                     = var.redis_engine
  engine_version             = var.redis_engine_version
  parameter_group_name       = var.parameter_group_name
  port                       = var.redis_port
  node_type                  = var.redis_node_type
  subnet_ids                 = data.aws_subnets.data_private_subnet.ids
  security_group_ids         = var.security_enabled == true && (var.full_enabled || var.networking_enabled == false) ? [module.security-groups.sgs.redis-sg.id] : []
  availability_zones         = var.redis_availability_zones
  replicas_per_node_group    = var.replicas_per_node_group
  num_node_groups            = var.num_node_groups
  auto_minor_version_upgrade = false
  automatic_failover_enabled = false
  at_rest_encryption_enabled = true
  transit_encryption_enabled = var.transit_encryption_enabled
  auth_token                 = var.auth_token
  kms_key_id                 = module.kms_redis.key_arn
  extra_tags                 = local.stackCommon.extra_tags
}

module "secure-redis-cluster" {
  source = "../../../_modules/elasticache"

  providers = {
    aws.stack = aws.stack
  }
  name        = "secure-redis-cluster"
  environment = var.environment
  label_order = var.label_order

  enable_elasticache_cluster = var.secure_redis_cluster_enabled && (var.full_enabled || var.networking_enabled == false)

  replication_enabled        = true
  number_cache_clusters      = 2
  engine                     = var.secure_redis_engine
  engine_version             = var.secure_redis_engine_version
  parameter_group_name       = var.secure_parameter_group_name
  port                       = var.secure_redis_port
  node_type                  = var.secure_redis_node_type
  subnet_ids                 = data.aws_subnets.data_private_subnet.ids
  security_group_ids         = var.security_enabled == true && (var.full_enabled || var.networking_enabled == false) ? [module.security-groups.sgs.secure-redis-sg.id] : []
  availability_zones         = var.secure_redis_availability_zones
  replicas_per_node_group    = var.secure_replicas_per_node_group
  num_node_groups            = var.secure_num_node_groups
  auto_minor_version_upgrade = false
  automatic_failover_enabled = false
  at_rest_encryption_enabled = true
  transit_encryption_enabled = var.transit_encryption_enabled
  auth_token                 = var.auth_token
  kms_key_id                 = module.kms_redis.key_arn
  extra_tags                 = local.stackCommon.extra_tags
}

##########################mysql######################

module "mysql" {
  source = "../../../_modules/mysql"
  providers = {
    aws.stack = aws.stack
  }

  name                   = "rds"
  environment            = var.environment
  label_order            = var.label_order
  enabled                = var.mysql_enabled && (var.full_enabled || var.networking_enabled == false)
  engine                 = var.mysql_engine
  engine_version         = var.mysql_engine_version
  instance_class         = var.mysql_instance_class
  replica_instance_class = var.mysql_replica_instance_class
  allocated_storage      = var.mysql_allocated_storage
  identifier             = ""
  snapshot_identifier    = var.db_snapshot_identifier
  enabled_read_replica   = var.enabled_read_replica
  kms_key_id             = module.kms_rds.key_arn
  enabled_replica        = var.enabled_replica
  skip_final_snapshot    = var.skip_final_snapshot

  # DB Details
  db_name  = var.mysql_database_name
  username = var.mysql_username
  port     = var.mysql_port

  vpc_security_group_ids = var.security_enabled == true && (var.full_enabled || var.networking_enabled == false) ? [module.security-groups.sgs.mysql-sg.id] : []

  maintenance_window = var.mysql_maintenance_window
  backup_window      = var.mysql_backup_window
  multi_az           = var.mysql_multi_az


  # disable backups to create DB faster
  backup_retention_period = var.mysql_backup_retention_period

  enabled_cloudwatch_logs_exports = var.mysql_enabled_cloudwatch_logs_exports

  # DB subnet group
  subnet_ids          = data.aws_subnets.data_private_subnet.ids
  publicly_accessible = var.mysql_publicly_accessible

  # DB parameter group
  family = var.mysql_family

  # DB option group
  major_engine_version       = var.mysql_major_engine_version
  auto_minor_version_upgrade = false
  # Snapshot name upon DB deletion

  # Database Deletion Protection
  deletion_protection = var.mysql_deletion_protection

  parameter_group_name = var.mysql_parameter_group_name
  parameters = var.mysql_parameters

  option_group_name = var.mysql_option_group_name
  option_group_enabled = var.mysql_option_group_enabled
  options = var.options

  extra_tags = local.stackCommon.extra_tags
}

module "s3_bucket" {
  source = "../../../_modules/s3"
  providers = {
    aws.stack = aws.stack
  }

  name        = var.s3_name
  environment = var.environment
  attributes  = var.s3_attributes
  label_order = var.label_order

  create_bucket_enabled = var.msk_cluster_enabled && var.s3_bucket_enabled && (var.full_enabled || var.networking_enabled == false)
  force_destroy         = var.s3_force_destroy
  versioning            = var.s3_versioning
  acl                   = var.s3_acl
  extra_tags            = local.stackCommon.extra_tags

}

module "eks-cluster" {
  source = "../../../_modules/eks"
  providers = {
    aws.stack = aws.stack
  }
  ## Tags
  name        = "eks"
  environment = var.environment
  label_order = var.label_order
  enabled     = var.eks_enabled && (var.full_enabled || var.networking_enabled == false)

  ## Network
  vpc_id                              = var.application_vpc_enabled == false ? var.application_vpc_id : join("", data.aws_vpc.application_vpc.*.id)
  eks_subnet_ids                      = data.aws_subnets.eks_private_subnet.ids
  worker_subnet_ids                   = data.aws_subnets.application_private_subnet.ids
  subnet_ids                          = data.aws_subnets.application_private_subnet.ids
  allowed_security_groups_cluster     = []
  allowed_security_groups_workers     = []
  additional_security_group_ids       = []
  allowed_cidr_blocks_cluster         = var.eks_allowed_cidr_blocks_cluster
  endpoint_private_access             = var.endpoint_private_access
  endpoint_public_access              = var.endpoint_public_access
  public_access_cidrs                 = var.allowed_cidr_blocks
  cluster_encryption_config_resources = ["secrets"]

  ## EKS Fargate
  fargate_enabled  = var.fargate_enabled
  fargate_profiles = var.fargate_profiles

  ## Cluster
  kubernetes_version       = var.kubernetes_version
  map_additional_iam_users = var.map_additional_iam_users
  map_additional_iam_roles = var.map_additional_iam_roles

  #Node Groups
  node_groups          = var.node_group_enabled && (var.full_enabled || var.networking_enabled == false) ? var.node_groups : {}
  node_group_kms_key_arn      = module.kms_ec2.key_arn
  
  apply_config_map_aws_auth                 = var.apply_config_map_aws_auth
  kubernetes_config_map_ignore_role_changes = var.kubernetes_config_map_ignore_role_changes
  ## logs
  enabled_cluster_log_types = var.enabled_cluster_log_types
  extra_tags                = local.stackCommon.extra_tags

}

data "aws_eks_cluster" "this" {
  count    = var.eks_enabled && var.node_group_enabled && (var.full_enabled || var.networking_enabled == false) ? 1 : 0
  provider = aws.stack
  name     = var.node_group_enabled == true && (var.full_enabled || var.networking_enabled == false) ? module.eks-cluster.eks_cluster_id : "test"
}

data "aws_eks_cluster_auth" "this" {
  count    = var.eks_enabled && var.node_group_enabled && (var.full_enabled || var.networking_enabled == false) ? 1 : 0
  provider = aws.stack
  name     = var.node_group_enabled == true && (var.full_enabled || var.networking_enabled == false) ? module.eks-cluster.eks_cluster_certificate_authority_data : "test"
}

provider "kubernetes" {
  host                   = var.eks_enabled ? data.aws_eks_cluster.this.endpoint : null
  cluster_ca_certificate = var.eks_enabled ? base64decode(data.aws_eks_cluster.this.certificate_authority[0].data) : null
  exec {
    api_version = "client.authentication.k8s.io/user"
    args        = ["eks", "get-token", "--cluster-name",var.eks_enabled ? module.eks-cluster.eks_cluster_id : null]
    command     = var.eks_enabled ? "aws" : null
  }
}

module "kafka" {
  source = "../../../_modules/msk"

  providers = {
    aws.stack = aws.stack
  }
  name        = "kafka"
  environment = var.environment
  label_order = var.label_order

  msk_cluster_enabled = var.msk_cluster_enabled && (var.full_enabled || var.networking_enabled == false)
  kafka_version       = var.kafka_version
  kafka_broker_number = var.kafka_broker_number

  broker_node_client_subnets  = data.aws_subnets.msk_private_subnet.ids
  broker_node_ebs_volume_size = var.broker_node_ebs_volume_size
  broker_node_instance_type   = var.broker_node_instance_type
  broker_node_security_groups = var.security_enabled == true && (var.full_enabled || var.networking_enabled == false) ? [module.security-groups.sgs.msk-sg.id] : []

  encryption_in_transit_client_broker = var.encryption_in_transit_client_broker
  encryption_in_transit_in_cluster    = var.encryption_in_transit_in_cluster
  encryption_at_rest_kms_key_arn      = module.kms_kafka.key_arn

  configuration_server_properties = var.configuration_server_properties

  jmx_exporter_enabled    = var.jmx_exporter_enabled
  node_exporter_enabled   = var.node_exporter_enabled
  cloudwatch_logs_enabled = var.cloudwatch_logs_enabled
  s3_logs_enabled         = var.s3_logs_enabled
  s3_logs_bucket          = module.s3_bucket.id
  s3_logs_prefix          = var.s3_logs_prefix

  scaling_max_capacity          = var.scaling_max_capacity
  scaling_target_value          = var.scaling_target_value
  auto_scaling_storage_enabled = var.auto_scaling_storage_enabled

  client_authentication_sasl_scram         = var.client_authentication_sasl_scram
  create_scram_secret_association          = var.create_scram_secret_association
  scram_secret_association_secret_arn_list = [module.secrets_manager.secret_arns]

  schema_registries = var.schema_registries
  schemas           = var.schemas
  extra_tags        = local.stackCommon.extra_tags

}

#####################################################--rds_route53--##########################################
module "rds_route53-record" {
  source = "../../../_modules/route53record"
  providers = {
    aws.stack = aws.ops
  }
  record_enabled = var.mysql_enabled && (var.full_enabled || var.networking_enabled == false)
  zone_id        = var.hosted_zone_id
  name           = format("%s-rds", var.environment)
  type           = var.route53_record_type
  ttl            = var.route53_record_ttl
  values         = split(":", module.mysql.db_instance_endpoint)[0]
  extra_tags     = local.stackCommon.extra_tags

}
#####################################################--redis_route53--##########################################
module "redis_route53-record" {
  source = "../../../_modules/route53record"
  providers = {
    aws.stack = aws.ops
  }
  record_enabled = var.redis_cluster_enabled && (var.full_enabled || var.networking_enabled == false)
  zone_id        = var.hosted_zone_id
  name           = format("%s-redis", var.environment)
  type           = var.route53_record_type
  ttl            = var.route53_record_ttl
  values         = module.redis-cluster.redis_endpoint
  extra_tags     = local.stackCommon.extra_tags

}

#####################################################secure-redis_route53--##########################################
module "secure_redis_route53-record" {
  source = "../../../_modules/route53record"
  providers = {
    aws.stack = aws.ops
  }
  record_enabled = var.secure_redis_cluster_enabled && (var.full_enabled || var.networking_enabled == false)
  zone_id        = var.hosted_zone_id
  name           = format("%s-secure-redis", var.environment)
  type           = var.route53_record_type
  ttl            = var.route53_record_ttl
  values         = module.secure-redis-cluster.redis_endpoint
  extra_tags     = local.stackCommon.extra_tags

}
#####################################################--eks_route53--##########################################
module "eks_route53-record" {
  source = "../../../_modules/route53record"
  providers = {
    aws.stack = aws.ops
  }
  record_enabled = var.eks_enabled && (var.full_enabled || var.networking_enabled == false)
  zone_id        = var.hosted_zone_id
  name           = format("%s-eks-api", var.environment)
  type           = var.route53_record_type
  ttl            = var.route53_record_ttl
  values         = var.eks_enabled && (var.full_enabled || var.networking_enabled == false) ? split("://", module.eks-cluster.eks_cluster_endpoint)[1] : ""
  extra_tags     = local.stackCommon.extra_tags

}

#####################################################--kafka_route53--##########################################
module "kafka_route53-record" {
  source = "../../../_modules/route53record"
  count  = var.kafka_broker_number
  providers = {
    aws.stack = aws.ops
  }
  record_enabled = var.msk_cluster_enabled && (var.full_enabled || var.networking_enabled == false)
  zone_id        = var.hosted_zone_id
  name           = format("%s-kafka-b%s", var.environment, count.index + 1)
  type           = var.route53_record_type
  ttl            = var.route53_record_ttl
  values         = var.msk_cluster_enabled && (var.full_enabled || var.networking_enabled == false) ? split(":", module.kafka.bootstrap_endpoints)[count.index] : ""
  #values         = var.msk_cluster_enabled && (var.full_enabled || var.networking_enabled == false) ? split(":", split(",", module.kafka.bootstrap_brokers_tls)[count.index])[0] : ""
  extra_tags     = local.stackCommon.extra_tags

}
#########################################################---iam_policy---#######################################

module "aws_iam_policy" {
  source = "../../../_modules/iam-policy"

  providers = {
    aws.stack = aws.stack
  }
  name           = "policy"
  environment    = var.environment
  label_order    = var.label_order
  policy_enabled = var.eks_enabled && var.node_group_enabled == true && var.policy_enabled && (var.full_enabled || var.networking_enabled == false)
  role_name      = var.eks_enabled && var.node_group_enabled == true && (var.full_enabled || var.networking_enabled == false) ? split("/", module.eks-cluster.iam_role_arn)[1] : ""

  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : [
            "iam:CreateServiceLinkedRole"
          ],
          "Resource" : "*",
          "Condition" : {
            "StringEquals" : {
              "iam:AWSServiceName" : "elasticloadbalancing.amazonaws.com"
            }
          }
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "ec2:DescribeAccountAttributes",
            "ec2:DescribeAddresses",
            "ec2:DescribeAvailabilityZones",
            "ec2:DescribeInternetGateways",
            "ec2:DescribeVpcs",
            "ec2:DescribeVpcPeeringConnections",
            "ec2:DescribeSubnets",
            "ec2:DescribeSecurityGroups",
            "ec2:DescribeInstances",
            "ec2:DescribeNetworkInterfaces",
            "ec2:DescribeTags",
            "ec2:GetCoipPoolUsage",
            "ec2:DescribeCoipPools",
            "elasticloadbalancing:DescribeLoadBalancers",
            "elasticloadbalancing:DescribeLoadBalancerAttributes",
            "elasticloadbalancing:DescribeListeners",
            "elasticloadbalancing:DescribeListenerCertificates",
            "elasticloadbalancing:DescribeSSLPolicies",
            "elasticloadbalancing:DescribeRules",
            "elasticloadbalancing:DescribeTargetGroups",
            "elasticloadbalancing:DescribeTargetGroupAttributes",
            "elasticloadbalancing:DescribeTargetHealth",
            "elasticloadbalancing:DescribeTags"
          ],
          "Resource" : "*"
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "cognito-idp:DescribeUserPoolClient",
            "acm:ListCertificates",
            "acm:DescribeCertificate",
            "iam:ListServerCertificates",
            "iam:GetServerCertificate",
            "waf-regional:GetWebACL",
            "waf-regional:GetWebACLForResource",
            "waf-regional:AssociateWebACL",
            "waf-regional:DisassociateWebACL",
            "wafv2:GetWebACL",
            "wafv2:GetWebACLForResource",
            "wafv2:AssociateWebACL",
            "wafv2:DisassociateWebACL",
            "shield:GetSubscriptionState",
            "shield:DescribeProtection",
            "shield:CreateProtection",
            "shield:DeleteProtection"
          ],
          "Resource" : "*"
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "ec2:AuthorizeSecurityGroupIngress",
            "ec2:RevokeSecurityGroupIngress"
          ],
          "Resource" : "*"
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "ec2:CreateSecurityGroup"
          ],
          "Resource" : "*"
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "ec2:CreateTags"
          ],
          "Resource" : "arn:aws:ec2:*:*:security-group/*",
          "Condition" : {
            "StringEquals" : {
              "ec2:CreateAction" : "CreateSecurityGroup"
            },
            "Null" : {
              "aws:RequestTag/elbv2.k8s.aws/cluster" : "false"
            }
          }
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "ec2:CreateTags",
            "ec2:DeleteTags"
          ],
          "Resource" : "arn:aws:ec2:*:*:security-group/*",
          "Condition" : {
            "Null" : {
              "aws:RequestTag/elbv2.k8s.aws/cluster" : "true",
              "aws:ResourceTag/elbv2.k8s.aws/cluster" : "false"
            }
          }
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "ec2:AuthorizeSecurityGroupIngress",
            "ec2:RevokeSecurityGroupIngress",
            "ec2:DeleteSecurityGroup"
          ],
          "Resource" : "*",
          "Condition" : {
            "Null" : {
              "aws:ResourceTag/elbv2.k8s.aws/cluster" : "false"
            }
          }
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "elasticloadbalancing:CreateLoadBalancer",
            "elasticloadbalancing:CreateTargetGroup"
          ],
          "Resource" : "*",
          "Condition" : {
            "Null" : {
              "aws:RequestTag/elbv2.k8s.aws/cluster" : "false"
            }
          }
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "elasticloadbalancing:CreateListener",
            "elasticloadbalancing:DeleteListener",
            "elasticloadbalancing:CreateRule",
            "elasticloadbalancing:DeleteRule"
          ],
          "Resource" : "*"
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "elasticloadbalancing:AddTags",
            "elasticloadbalancing:RemoveTags"
          ],
          "Resource" : [
            "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*",
            "arn:aws:elasticloadbalancing:*:*:loadbalancer/net/*/*",
            "arn:aws:elasticloadbalancing:*:*:loadbalancer/app/*/*"
          ],
          "Condition" : {
            "Null" : {
              "aws:RequestTag/elbv2.k8s.aws/cluster" : "true",
              "aws:ResourceTag/elbv2.k8s.aws/cluster" : "false"
            }
          }
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "elasticloadbalancing:AddTags",
            "elasticloadbalancing:RemoveTags"
          ],
          "Resource" : [
            "arn:aws:elasticloadbalancing:*:*:listener/net/*/*/*",
            "arn:aws:elasticloadbalancing:*:*:listener/app/*/*/*",
            "arn:aws:elasticloadbalancing:*:*:listener-rule/net/*/*/*",
            "arn:aws:elasticloadbalancing:*:*:listener-rule/app/*/*/*"
          ]
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "elasticloadbalancing:AddTags"
          ],
          "Resource" : [
            "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*",
            "arn:aws:elasticloadbalancing:*:*:loadbalancer/net/*/*",
            "arn:aws:elasticloadbalancing:*:*:loadbalancer/app/*/*"
          ],
          "Condition" : {
            "StringEquals" : {
              "elasticloadbalancing:CreateAction" : [
                "CreateTargetGroup",
                "CreateLoadBalancer"
              ]
            },
            "Null" : {
              "aws:RequestTag/elbv2.k8s.aws/cluster" : "false"
            }
          }
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "elasticloadbalancing:ModifyLoadBalancerAttributes",
            "elasticloadbalancing:SetIpAddressType",
            "elasticloadbalancing:SetSecurityGroups",
            "elasticloadbalancing:SetSubnets",
            "elasticloadbalancing:DeleteLoadBalancer",
            "elasticloadbalancing:ModifyTargetGroup",
            "elasticloadbalancing:ModifyTargetGroupAttributes",
            "elasticloadbalancing:DeleteTargetGroup"
          ],
          "Resource" : "*",
          "Condition" : {
            "Null" : {
              "aws:ResourceTag/elbv2.k8s.aws/cluster" : "false"
            }
          }
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "elasticloadbalancing:RegisterTargets",
            "elasticloadbalancing:DeregisterTargets"
          ],
          "Resource" : "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*"
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "elasticloadbalancing:SetWebAcl",
            "elasticloadbalancing:ModifyListener",
            "elasticloadbalancing:AddListenerCertificates",
            "elasticloadbalancing:RemoveListenerCertificates",
            "elasticloadbalancing:ModifyRule"
          ],
          "Resource" : "*"
        }
      ]
    }
  )
}

module "kms_ec2" {
  source = "../../../_modules/kms"

  providers = {
    aws.stack = aws.stack
  }
  kms_key_enabled = (var.es_ec2_enabled || var.etcd_ec2_enabled || var.eks_enabled) && (var.full_enabled || var.networking_enabled == false)
  kms = {
    description              = var.ec2_kms_description,
    key_usage                = var.ec2_key_usage,
    customer_master_key_spec = var.ec2_customer_master_key_spec,
    policy                   = data.aws_iam_policy_document.ec2.json,
    enable_key_rotation      = var.ec2_enable_key_rotation,
    multi_region             = var.kms_ec2_multi_region,
  }
  stackCommon = local.stackCommon
  alias       = format("alias/%s-ec2", var.environment)
}

data "aws_iam_policy_document" "ec2" {
  version   = "2012-10-17"
  policy_id = "ec2-encryption"
  statement {
    sid    = "Allow access through RDS for all principals in the account that are authorized to use RDS"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:CreateGrant",
      "kms:ListGrants",
      "kms:DescribeKey"
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "kms:CallerAccount"
      values   = [data.aws_caller_identity.stack.account_id]
    }
    condition {
      test     = "StringLike"
      variable = "kms:ViaService"
      values   = ["ec2.*.amazonaws.com"]
    }
  }
  statement {
    sid    = "Allow direct access to key metadata to the account"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [format("arn:aws:iam::%s:root", data.aws_caller_identity.stack.account_id)]
    }
    actions   = ["*"]
    resources = ["*"]
  }
}

####----------------------------------------------------------------------------------
## Terraform module to create etcd ec2 instance module on AWS.
####----------------------------------------------------------------------------------
module "etcd_ec2" {
  source = "../../../_modules/ec2"
  providers = {
    aws.stack = aws.stack
  }
  instance_enabled = var.etcd_ec2_enabled && (var.full_enabled || var.networking_enabled == false)
  name             = format("etcd-%s", var.product)
  environment      = var.environment
  product          = var.product
  label_order      = var.label_order

  #Instance
  instance_count = var.etcd_ec2_instance_count
  ami            = var.etcd_ec2_ami
  instance_type  = var.etcd_ec2_instance_type

  #Keypair
  public_key = var.public_key
  key_name   = var.key_name

  #Networking
  subnet_ids = data.aws_subnets.data_private_subnet.ids
  sg_ids     = var.security_enabled == true && (var.full_enabled || var.networking_enabled == false) ? [module.security-groups.sgs.etcd-ec2-sg.id, module.security-groups.sgs.ssh-sg.id] : []

  #IAM
  # iam_instance_profile = module.iam-role.name

  #Root Volume
  root_block_device = var.etcd_ec2_root_block_device

  #EBS Volume
  ebs_block_device = var.etcd_ec2_ebs_block_device
  kms_key_id       = module.kms_ec2.key_arn

  #Tags
  instance_tags = {
     Deploy = format("%s-etcd-cluster", var.environment)
  }

  #Mount EBS With User Data
  user_data = file("./scripts/user-data-hostname.sh")
}

#####################################################etcd-ec2_route53--##########################################
module "etcd_ec2_route53-record" {
  source = "../../../_modules/route53record"
  providers = {
    aws.stack = aws.ops
  }
  count          = var.etcd_ec2_enabled && (var.full_enabled || var.networking_enabled == false) ? var.etcd_ec2_instance_count : 0
  record_enabled = var.etcd_ec2_enabled && (var.full_enabled || var.networking_enabled == false)
  zone_id        = var.hosted_zone_id
  name           = format("%s-etcd-%s", var.environment, count.index +1)
  type           = var.ec2_route53_record_type
  ttl            = var.route53_record_ttl
  values         = module.etcd_ec2.private_ip[count.index]
  extra_tags     = local.stackCommon.extra_tags
}

####----------------------------------------------------------------------------------
## Terraform module to create elasticsearch ec2 instance module on AWS.
####----------------------------------------------------------------------------------
module "es_ec2" {
  source = "../../../_modules/ec2"
  providers = {
    aws.stack = aws.stack
  }
  instance_enabled = var.es_ec2_enabled && (var.full_enabled || var.networking_enabled == false)
  name             = format("es-%s", var.product)
  environment      = var.environment
  product          = var.product
  label_order      = var.label_order

  #Instance
  instance_count = var.es_ec2_instance_count
  ami            = var.es_ec2_ami
  instance_type  = var.es_ec2_instance_type

  #Keypair
  public_key = var.public_key
  key_name   = var.key_name

  #Networking
  subnet_ids = data.aws_subnets.data_private_subnet.ids
  sg_ids     = var.security_enabled == true && (var.full_enabled || var.networking_enabled == false) ? [module.security-groups.sgs.es-ec2-sg.id, module.security-groups.sgs.ssh-sg.id] : []

  #IAM
  # iam_instance_profile = module.iam-role.name

  #Root Volume
  root_block_device = var.es_ec2_root_block_device

  #EBS Volume
  ebs_block_device = var.es_ec2_ebs_block_device
  kms_key_id       = module.kms_ec2.key_arn

  #Tags
  instance_tags = {
     Deploy = format("%s-es-cluster", var.environment)
  }

  #Set Hostname With User Data
  user_data = file("./scripts/user-data-hostname.sh")
}

#####################################################etcd-ec2_route53--##########################################
module "es_ec2_route53-record" {
  source = "../../../_modules/route53record"
  providers = {
    aws.stack = aws.ops
  }
  count          = var.es_ec2_enabled && (var.full_enabled || var.networking_enabled == false) ? var.es_ec2_instance_count : 0
  record_enabled = var.es_ec2_enabled && (var.full_enabled || var.networking_enabled == false)
  zone_id        = var.hosted_zone_id
  name           = format("%s-es-%s", var.environment, count.index +1)
  type           = var.ec2_route53_record_type
  ttl            = var.route53_record_ttl
  values         = module.es_ec2.private_ip[count.index]
  extra_tags     = local.stackCommon.extra_tags
}



##-----------------------------------------------------------------------------
## nlb module call for elastic search
##-----------------------------------------------------------------------------
module "es_nlb" {
  source = "../../../_modules/nlb"
  providers = {
    aws.stack = aws.stack
  }
  name                       = "elastic-nlb"
  environment                = var.environment
  label_order                = var.label_order
  enable                     = var.es_nlb_enabled && var.es_ec2_enabled && (var.full_enabled || var.networking_enabled == false)
  internal                   = true
  load_balancer_type         = "network"
  security_groups            = var.security_enabled == true && (var.full_enabled || var.networking_enabled == false) ? [module.security-groups.sgs.es-nlb-sg.id] : []
  instance_count             = var.es_ec2_instance_count
  subnets                    = data.aws_subnets.data_private_subnet.ids
  target_id                  = module.es_ec2.instance_id
  vpc_id                     = var.data_vpc_enabled == false ? var.data_vpc_id : join("", data.aws_vpc.data_vpc.*.id)
  enable_deletion_protection = var.es_nlb_enable_deletion_protection
  with_target_group          = var.es_nlb_with_target_group
  # # Only http or https can be used in single time. 
  http_tcp_listeners = var.es_nlb_http_tcp_listeners
  https_listeners    = var.es_nlb_https_listeners
  target_groups      = var.es_target_groups
}


# #####################################################es-nlb_route53--##########################################
module "es_nlb_route53-record" {
  source = "../../../_modules/route53record"
  providers = {
    aws.stack = aws.ops
  }
  record_enabled = var.es_nlb_enabled && var.es_ec2_enabled && (var.full_enabled || var.networking_enabled == false)
  zone_id        = var.hosted_zone_id
  name           = format("%s-es-nlb", var.environment)
  type           = var.route53_record_type
  ttl            = var.route53_record_ttl
  values         = module.es_nlb.dns_name
  extra_tags     = local.stackCommon.extra_tags
}


