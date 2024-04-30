terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      configuration_aliases = [aws.stack]
      version               = ">= 3.1.15"
    }
  }
}

locals {
  tags = merge(
    var.tags,
    {
      "kubernetes.io/cluster/${var.cluster_name}" = "owned"
      "Environ"                                   = var.environ
      "Product"                                   = var.product

    }
  )
  node_group_tags = merge(
    var.tags,
    var.extra_tags,
    {
      "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    },
    {
      "k8s.io/cluster-autoscaler/${var.cluster_name}" = "owned"
    },
    {
      "k8s.io/cluster-autoscaler/enabled" = "${var.node_group_enabled}"
    }
  )
  enabled = var.enabled ? true : false
  # Use a custom launch_template if one was passed as an input
  # Otherwise, use the default in this project
  userdata_vars = {
    before_cluster_joining_userdata = var.before_cluster_joining_userdata
  }
}

data "aws_vpc" "application_vpc" {
  provider = aws.stack
  tags = {
    Name = "${var.environment}-application" # Replace with your desired tag key-value pair
  }
}

data "aws_subnets" "application_private_subnet" {
  provider = aws.stack
  for_each = var.node_groups
  filter {
    name   = "vpc-id"
    values = var.application_vpc_enabled == false ? [var.application_vpc_id] : data.aws_vpc.application_vpc.*.id
  }
  tags = {
    "private" = "1"
    "Component"    = "${each.value.subnet_component_tag}"
  }
}
module "labels" {
  source = "./../../../labels"


  name        = var.name
  environment = var.environment
  managedby   = var.managedby
  delimiter   = var.delimiter
  extra_tags  = local.node_group_tags
  attributes  = compact(concat(var.attributes, ["node-group"]))
  label_order = var.label_order
}


#Module:     : NODE GROUP
#Description : Creating a node group for eks cluster
resource "aws_eks_node_group" "default" {
  provider = aws.stack

  for_each        = var.node_groups
  cluster_name    = var.cluster_name
  node_group_name = format("%s-%s", module.labels.id, each.value.node_group_name)
  node_role_arn   = var.node_role_arn
  subnet_ids      = data.aws_subnets.application_private_subnet[each.key].ids
#  instance_types  = each.value.node_group_instance_types
  labels          = each.value.kubernetes_labels
  release_version = each.value.ami_release_version
  version         = var.kubernetes_version
  tags            = module.labels.tags
  capacity_type   = each.value.node_group_capacity_type
  ami_type        = each.value.ami_type

  scaling_config {
    desired_size = each.value.node_group_desired_size
    max_size     = each.value.node_group_max_size
    min_size     = each.value.node_group_min_size
  }

  launch_template {
    name    = aws_launch_template.default[each.key].name
    version = aws_launch_template.default[each.key].latest_version
  }

  dynamic "taint" {
    for_each = each.value.taints
    content {
      key    = taint.value.taint_key
      value  = taint.value.taint_value
      effect = taint.value.taint_effect
    }
  }

  depends_on = [aws_launch_template.default]
}


resource "aws_launch_template" "default" {
  provider = aws.stack

  for_each = var.node_groups
   instance_type = each.value.node_group_instance_type

   block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = each.value.node_group_volume_size
      volume_type = each.value.node_group_volume_type
      kms_key_id  = var.kms_key_arn
      encrypted   = var.ebs_encryption
    }
  }

  name                   = format("%s-%s", module.labels.id, each.value.node_group_name)
  update_default_version = true
#  image_id               = var.ami_release_version

  dynamic "tag_specifications" {
    for_each = var.resources_to_tag
    content {
      resource_type = tag_specifications.value
      tags          = module.labels.tags
    }
  }

  vpc_security_group_ids = null
  user_data              = null
  tags                   = module.labels.tags
}
