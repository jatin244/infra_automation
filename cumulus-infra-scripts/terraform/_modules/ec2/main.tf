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

# data "aws_ami" "ubuntu" {
#   most_recent = "true"
#   filter {
#     name   = "name"
#     values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
#   }
#   owners = ["099720109477"]
# }

##----------------------------------------------------------------------------------
## resource for generating or importing an SSH public key file into AWS.
##----------------------------------------------------------------------------------
resource "aws_key_pair" "default" {
  provider = aws.stack
  count    = var.enable_key_pair == true && var.key_name == "" ? 1 : 0

  key_name   = format("%s-key-pair", module.labels.id)
  public_key = var.public_key == "" ? file(var.key_path) : var.public_key
  tags       = module.labels.tags
}

##----------------------------------------------------------------------------------
## Below Terraform module to create an EC2 resource on AWS with Elastic IP Addresses and Elastic Block Store.
##----------------------------------------------------------------------------------
resource "aws_instance" "default" {
  provider = aws.stack
  count    = var.instance_enabled == true ? var.instance_count : 0

  ami                                  = var.ami #== "" ? data.aws_ami.ubuntu.id : var.ami
  ebs_optimized                        = var.ebs_optimized
  instance_type                        = var.instance_type
  key_name                             = var.key_name == "" ? join("", aws_key_pair.default[*].key_name) : var.key_name
  monitoring                           = var.monitoring
  vpc_security_group_ids               = var.sg_ids
  subnet_id                            = element(distinct(compact(concat(var.subnet_ids))), count.index)
  associate_public_ip_address          = var.associate_public_ip_address
  disable_api_termination              = var.disable_api_termination
  instance_initiated_shutdown_behavior = var.instance_initiated_shutdown_behavior
  placement_group                      = var.placement_group
  tenancy                              = var.tenancy
  host_id                              = var.host_id
  cpu_core_count                       = var.cpu_core_count
  user_data                            = var.user_data
  iam_instance_profile                 = join("", aws_iam_instance_profile.default[*].name)
  source_dest_check                    = var.source_dest_check
  ipv6_address_count                   = var.ipv6_address_count
  ipv6_addresses                       = var.ipv6_addresses
  hibernation                          = var.hibernation

  dynamic "root_block_device" {
    for_each = var.root_block_device
    content {
      delete_on_termination = lookup(root_block_device.value, "delete_on_termination", null)
      encrypted             = lookup(root_block_device.value, "encrypted", null)
      iops                  = lookup(root_block_device.value, "iops", null)
      kms_key_id            = try(var.kms_key_id, null)
      volume_size           = lookup(root_block_device.value, "volume_size", null)
      volume_type           = lookup(root_block_device.value, "volume_type", null)
      tags = merge(module.labels.tags,
        {
          "Name" = format("%s-root-volume%s%s", module.labels.id, var.delimiter, (count.index + 1))
        },
        {
         "Environ" = var.environment
         "Product" = var.product
        },
        var.tags
      )
    }
  }

  dynamic "ebs_block_device" {
    for_each = var.ebs_block_device

    content {
      delete_on_termination = lookup(ebs_block_device.value, "delete_on_termination", null)
      device_name           = ebs_block_device.value.device_name
      encrypted             = lookup(ebs_block_device.value, "encrypted", null)
      iops                  = lookup(ebs_block_device.value, "iops", null)
      kms_key_id            = try(var.kms_key_id, null)
      snapshot_id           = lookup(ebs_block_device.value, "snapshot_id", null)
      volume_size           = lookup(ebs_block_device.value, "volume_size", null)
      volume_type           = lookup(ebs_block_device.value, "volume_type", null)
      throughput            = lookup(ebs_block_device.value, "throughput", null)
      tags = merge(module.labels.tags,
        {
          "Name" = format("%s-secondary-volume%s%s", module.labels.id, var.delimiter, (count.index + 1))
        },
        {
          "device_name" = ebs_block_device.value.device_name
        },
        {
          "Environ" = var.environment
          "Product" = var.product
        },
        var.instance_tags
      )
    }
  }

  dynamic "ephemeral_block_device" {
    for_each = var.ephemeral_block_device
    content {
      device_name  = ephemeral_block_device.value.device_name
      no_device    = lookup(ephemeral_block_device.value, "no_device", null)
      virtual_name = lookup(ephemeral_block_device.value, "virtual_name", null)
    }
  }

  metadata_options {
    http_endpoint               = var.metadata_http_endpoint_enabled
    instance_metadata_tags      = var.instance_metadata_tags_enabled
    http_put_response_hop_limit = var.metadata_http_put_response_hop_limit
    http_tokens                 = var.metadata_http_tokens_required
  }

  credit_specification {
    cpu_credits = var.cpu_credits
  }

  dynamic "network_interface" {
    for_each = var.network_interface
    content {
      device_index          = network_interface.value.device_index
      network_interface_id  = lookup(network_interface.value, "network_interface_id", null)
      delete_on_termination = lookup(network_interface.value, "delete_on_termination", false)
    }
  }

  tags = merge(
    module.labels.tags,
    {
      "Name" = format("%s%s%s", module.labels.id, var.delimiter, (count.index + 1))
    },
    {
      "Environ" = var.environment
      "Product" = var.product
    },
    var.instance_tags
  )

  lifecycle {
    # Due to several known issues in Terraform AWS provider related to arguments of aws_instance:
    # (eg, https://github.com/terraform-providers/terraform-provider-aws/issues/2036)
    # we have to ignore changes in the following arguments
    ignore_changes = [
      private_ip,
    ]
  }
}

##----------------------------------------------------------------------------------
## Provides an Elastic IP resource..
##----------------------------------------------------------------------------------
resource "aws_eip" "default" {
  provider = aws.stack
  count    = var.instance_enabled == true && var.assign_eip_address == true ? var.instance_count : 0

  network_interface = element(aws_instance.default[*].primary_network_interface_id, count.index)

  tags = merge(
    module.labels.tags,
    {
      "Name" = format("%s%s%s-eip", module.labels.id, var.delimiter, (count.index + 1))
    }
  )
}

##----------------------------------------------------------------------------------
## Provides an IAM instance profile.
##----------------------------------------------------------------------------------
resource "aws_iam_instance_profile" "default" {
  provider = aws.stack
  count    = var.instance_enabled == true && var.instance_profile_enabled ? 1 : 0
  name     = format("%s%sinstance-profile", module.labels.id, var.delimiter)
  role     = var.iam_instance_profile
}

##----------------------------------------------------------------------------------
## Below resource will create ROUTE-53 resource for memcached.
##----------------------------------------------------------------------------------
resource "aws_route53_record" "default" {
  provider = aws.stack
  count    = var.instance_enabled == true && var.dns_enabled ? var.instance_count : 0
  zone_id  = var.dns_zone_id
  name     = format("%s%s%s", var.hostname, var.delimiter, (count.index + 1))
  type     = var.type
  ttl      = var.ttl
  records  = [element(aws_instance.default[*].private_dns, count.index)]
}

##----------------------------------------------------------------------------------
## Below Provides an EC2 Spot Instance Request resource. This allows instances to be requested on the spot market..
##----------------------------------------------------------------------------------
resource "aws_spot_instance_request" "default" {
  provider = aws.stack
  count    = var.spot_instance_enabled == true ? var.spot_instance_count : 0

  spot_price                     = var.spot_price
  wait_for_fulfillment           = var.spot_wait_for_fulfillment
  spot_type                      = var.spot_type
  launch_group                   = var.spot_launch_group
  block_duration_minutes         = var.spot_block_duration_minutes
  instance_interruption_behavior = var.spot_instance_interruption_behavior
  valid_until                    = var.spot_valid_until
  valid_from                     = var.spot_valid_from

  ami                                  = var.ami #== "" ? data.aws_ami.ubuntu.id : var.ami
  ebs_optimized                        = var.ebs_optimized
  instance_type                        = var.instance_type
  key_name                             = join("", aws_key_pair.default[*].key_name)
  monitoring                           = var.monitoring
  vpc_security_group_ids               = var.sg_ids
  subnet_id                            = element(distinct(compact(concat(var.subnet_ids))), count.index)
  associate_public_ip_address          = var.associate_public_ip_address
  disable_api_termination              = var.disable_api_termination
  instance_initiated_shutdown_behavior = var.instance_initiated_shutdown_behavior
  placement_group                      = var.placement_group
  tenancy                              = var.tenancy
  host_id                              = var.host_id
  cpu_core_count                       = var.cpu_core_count
  user_data                            = var.user_data
  iam_instance_profile                 = join("", aws_iam_instance_profile.default[*].name)
  source_dest_check                    = var.source_dest_check
  ipv6_address_count                   = var.ipv6_address_count
  ipv6_addresses                       = var.ipv6_addresses
  hibernation                          = var.hibernation

  dynamic "root_block_device" {
    for_each = var.root_block_device
    content {
      delete_on_termination = lookup(root_block_device.value, "delete_on_termination", null)
      encrypted             = true
      iops                  = lookup(root_block_device.value, "iops", null)
      kms_key_id            = lookup(root_block_device.value, "kms_key_id", null)
      volume_size           = lookup(root_block_device.value, "volume_size", null)
      volume_type           = lookup(root_block_device.value, "volume_type", null)
      tags = merge(module.labels.tags,
        {
          "Name" = format("%s-root-volume%s%s", module.labels.id, var.delimiter, (count.index + 1))
        },
        var.tags
      )
    }
  }

  dynamic "ebs_block_device" {
    for_each = var.ebs_block_device
    content {
      delete_on_termination = lookup(ebs_block_device.value, "delete_on_termination", null)
      device_name           = ebs_block_device.value.device_name
      encrypted             = lookup(ebs_block_device.value, "encrypted", null)
      iops                  = lookup(ebs_block_device.value, "iops", null)
      kms_key_id            = lookup(ebs_block_device.value, "kms_key_id", null)
      snapshot_id           = lookup(ebs_block_device.value, "snapshot_id", null)
      volume_size           = lookup(ebs_block_device.value, "volume_size", null)
      volume_type           = lookup(ebs_block_device.value, "volume_type", null)
      throughput            = lookup(ebs_block_device.value, "throughput", null)
      tags = merge(module.labels.tags,
        { "Name" = format("%s-ebs-volume%s%s", module.labels.id, var.delimiter, (count.index + 1))
        },
        var.tags
      )
    }
  }

  dynamic "ephemeral_block_device" {
    for_each = var.ephemeral_block_device
    content {
      device_name  = ephemeral_block_device.value.device_name
      no_device    = lookup(ephemeral_block_device.value, "no_device", null)
      virtual_name = lookup(ephemeral_block_device.value, "virtual_name", null)
    }
  }

  metadata_options {
    http_endpoint               = var.metadata_http_endpoint_enabled
    http_put_response_hop_limit = var.metadata_http_put_response_hop_limit
    http_tokens                 = var.metadata_http_tokens_required
  }

  credit_specification {
    cpu_credits = var.cpu_credits
  }

  dynamic "network_interface" {
    for_each = var.network_interface
    content {
      device_index          = network_interface.value.device_index
      network_interface_id  = lookup(network_interface.value, "network_interface_id", null)
      delete_on_termination = lookup(network_interface.value, "delete_on_termination", false)
    }
  }

  tags = merge(
    module.labels.tags,
    {

      "Name" = format("%s%s%s", module.labels.id, var.delimiter, (count.index + 1))
    },
    var.spot_instance_tags
  )

  lifecycle {
    # Due to several known issues in Terraform AWS provider related to arguments of aws_instance:
    # (eg, https://github.com/terraform-providers/terraform-provider-aws/issues/2036)
    # we have to ignore changes in the following arguments
    ignore_changes = [
      private_ip,
    ]
  }
}
