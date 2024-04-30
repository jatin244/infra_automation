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

locals {
  cloudwatch_log_group = var.msk_cluster_enabled && var.create_cloudwatch_log_group ? aws_cloudwatch_log_group.this[0].name : var.cloudwatch_log_group_name
  broker_endpoints = var.msk_cluster_enabled ? join(":", flatten(data.aws_msk_broker_nodes.msk-cluster[0].node_info_list[*].endpoints)) : ""
}

data "aws_msk_broker_nodes" "msk-cluster" {
  provider               = aws.stack
  count = var.msk_cluster_enabled ? 1 : 0

  cluster_arn = one(aws_msk_cluster.msk-cluster[*].arn)
}

resource "aws_msk_cluster" "msk-cluster" {
  provider               = aws.stack
  count                  = var.msk_cluster_enabled ? 1 : 0
  cluster_name           = format("%s-msk-cluster", module.labels.id)
  kafka_version          = var.kafka_version
  number_of_broker_nodes = var.kafka_broker_number

  broker_node_group_info {
    client_subnets  = var.broker_node_client_subnets
    instance_type   = var.broker_node_instance_type
    security_groups = var.broker_node_security_groups
    storage_info {
      ebs_storage_info {
        volume_size = var.broker_node_ebs_volume_size
      }
    }
  }
  dynamic "client_authentication" {
    for_each = length(var.client_authentication_tls_certificate_authority_arns) > 0 || var.client_authentication_sasl_scram || var.client_authentication_sasl_iam ? [1] : []

    content {
      unauthenticated = true
      dynamic "tls" {
        for_each = length(var.client_authentication_tls_certificate_authority_arns) > 0 ? [1] : []
        content {
          certificate_authority_arns = var.client_authentication_tls_certificate_authority_arns
        }
      }

      dynamic "sasl" {
        for_each = var.client_authentication_sasl_iam ? [1] : []
        content {
          iam = var.client_authentication_sasl_iam
        }
      }

      dynamic "sasl" {
        for_each = var.client_authentication_sasl_scram ? [1] : []
        content {
          scram = var.client_authentication_sasl_scram
        }
      }
    }
  }

  configuration_info {
    arn      = join("", aws_msk_configuration.this.*.arn)
    revision = join("", aws_msk_configuration.this.*.latest_revision)
  }

  encryption_info {
    encryption_in_transit {
      client_broker = var.encryption_in_transit_client_broker
      in_cluster    = var.encryption_in_transit_in_cluster
    }
    encryption_at_rest_kms_key_arn = var.encryption_at_rest_kms_key_arn
  }

  open_monitoring {
    prometheus {
      jmx_exporter {
        enabled_in_broker = var.jmx_exporter_enabled
      }
      node_exporter {
        enabled_in_broker = var.node_exporter_enabled
      }
    }
  }

  logging_info {
    broker_logs {
      cloudwatch_logs {
        enabled   = var.cloudwatch_logs_enabled
        log_group = var.cloudwatch_logs_enabled ? local.cloudwatch_log_group : null
      }
      firehose {
        enabled         = var.firehose_logs_enabled
        delivery_stream = var.firehose_delivery_stream
      }
      s3 {
        enabled = var.s3_logs_enabled
        bucket  = var.s3_logs_bucket
        prefix  = var.s3_logs_prefix
      }
    }
  }

  timeouts {
    create = lookup(var.timeouts, "create", null)
    update = lookup(var.timeouts, "update", null)
    delete = lookup(var.timeouts, "delete", null)
  }

  # required for appautoscaling
  lifecycle {
    ignore_changes = [broker_node_group_info[0].storage_info]
  }

  tags = merge(
    module.labels.tags,
    var.msk_cluster_tags
  )
}

resource "aws_msk_serverless_cluster" "serverless" {
  count = var.aws_msk_serverless_cluster_enabled ? 1 : 0

  provider     = aws.stack
  cluster_name = format("%s-cloudwatch", module.labels.id)
  vpc_config {
    subnet_ids         = var.broker_node_client_subnets
    security_group_ids = var.broker_node_security_groups
  }

  client_authentication {
    sasl {
      iam {
        enabled = var.serverless_cluster_iam_authentication_enabled
      }
    }
  }
}

resource "aws_msk_configuration" "this" {
  provider          = aws.stack
  count             = var.msk_cluster_enabled ? 1 : 0
  name              = format("%s-configuration", module.labels.id)
  description       = var.configuration_description
  kafka_versions    = [var.kafka_version]
  server_properties = join("\n", [for k, v in var.configuration_server_properties : format("%s = %s", k, v)])
}

resource "aws_msk_scram_secret_association" "this" {
  provider = aws.stack
  count    = var.msk_cluster_enabled && var.create_scram_secret_association && var.client_authentication_sasl_scram ? 1 : 0

  cluster_arn     = aws_msk_cluster.msk-cluster[0].arn
  secret_arn_list = var.scram_secret_association_secret_arn_list
}

resource "aws_cloudwatch_log_group" "this" {
  provider = aws.stack
  count    = var.msk_cluster_enabled && var.create_cloudwatch_log_group ? 1 : 0

  name              = format("%s-cloudwatch", module.labels.id)
  retention_in_days = var.cloudwatch_log_group_retention_in_days
  kms_key_id        = var.cloudwatch_log_group_kms_key_id

  tags = merge(
    module.labels.tags,
    var.msk_cluster_cloudwatch_log_group_tags
  )
}

resource "aws_appautoscaling_target" "this" {
  provider = aws.stack
  count    = var.msk_cluster_enabled && var.auto_scaling_storage_enabled ? 1 : 0

  max_capacity       = var.scaling_max_capacity
  min_capacity       = 1
  role_arn           = var.scaling_role_arn
  resource_id        = aws_msk_cluster.msk-cluster[0].arn
  scalable_dimension = "kafka:broker-storage:VolumeSize"
  service_namespace  = "kafka"
}

resource "aws_appautoscaling_policy" "this" {
  provider = aws.stack
  count    = var.msk_cluster_enabled && var.auto_scaling_storage_enabled ? 1 : 0

  name               = "${var.name}-broker-storage-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_msk_cluster.msk-cluster[0].arn
  scalable_dimension = aws_appautoscaling_target.this[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.this[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "KafkaBrokerStorageUtilization"
    }

    target_value = var.scaling_target_value
  }
}

resource "aws_glue_registry" "this" {
  provider = aws.stack
  for_each = var.msk_cluster_enabled && var.create_schema_registry ? var.schema_registries : {}

  registry_name = each.value.name
  description   = lookup(each.value, "description", null)

  tags = merge(
    module.labels.tags,
    var.glue_registry_tags
  )
}

resource "aws_glue_schema" "this" {
  provider = aws.stack
  for_each = var.msk_cluster_enabled && var.create_schema_registry ? var.schemas : {}

  schema_name       = each.value.schema_name
  description       = lookup(each.value, "description", null)
  registry_arn      = aws_glue_registry.this[each.value.schema_registry_name].arn
  data_format       = "AVRO"
  compatibility     = each.value.compatibility
  schema_definition = each.value.schema_definition

  tags = merge(
    module.labels.tags,
    var.glue_schema_tags
  )
}
