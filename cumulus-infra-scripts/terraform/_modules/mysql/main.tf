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

resource "random_id" "password" {
  count       = var.enabled ? 1 : 0
  byte_length = 20
}

locals {
  monitoring_role_arn = var.enabled_monitoring_role ? aws_iam_role.enhanced_monitoring[0].arn : var.monitoring_role_arn

  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.final_snapshot_identifier_prefix}-${var.identifier}-${try(random_id.snapshot_identifier[0].hex, "")}"

  identifier        = var.use_identifier_prefix ? null : var.identifier
  identifier_prefix = var.use_identifier_prefix ? "${var.identifier}-" : null

  monitoring_role_name        = var.monitoring_role_use_name_prefix ? null : var.monitoring_role_name
  monitoring_role_name_prefix = var.monitoring_role_use_name_prefix ? "${var.monitoring_role_name}-" : null
  db_subnet_group_name        = var.enabled_db_subnet_group ? join("", aws_db_subnet_group.db_subnet_group.*.id) : var.db_subnet_group_name

  # Replicas will use source metadata
  username       = var.replicate_source_db != null ? null : var.username
  password       = var.password == "" ? join("", random_id.password.*.b64_url) : var.password
  engine         = var.replicate_source_db != null ? null : var.engine
  engine_version = var.replicate_source_db != null ? null : var.engine_version

  name = var.use_name_prefix ? null : var.name
  //  name_prefix = var.use_name_prefix ? "${var.name}-" : null

  description = coalesce(var.option_group_description, format("%s option group", var.name))
}

# Ref. https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html#genref-aws-service-namespaces
data "aws_partition" "current" {}

resource "random_id" "snapshot_identifier" {
  count = var.enabled && !var.skip_final_snapshot ? 1 : 0

  keepers = {
    id = var.identifier
  }

  byte_length = 4
}


resource "aws_db_subnet_group" "db_subnet_group" {
  count = var.enabled && var.enabled_db_subnet_group ? 1 : 0
  #name = module.labels.id
  provider    = aws.stack
  name        = module.labels.id
  description = format("Database subnet group for%s%s", var.delimiter, module.labels.id)
  subnet_ids  = var.subnet_ids

  tags = merge(
    module.labels.tags,
    var.db_subnet_group_tags
  )
}


resource "aws_db_parameter_group" "main" {
  count = var.enabled && (var.parameter_group_name == null) ? 1 : 0

  provider    = aws.stack
  name = format("%s-pg", module.labels.id)
  description = format("Database parameter group for%s%s", var.delimiter, module.labels.id)
  family      = var.family

  dynamic "parameter" {
    for_each = var.parameters
    content {
      name         = parameter.value.name
      value        = parameter.value.value
      apply_method = lookup(parameter.value, "apply_method", null)
    }
  }

  tags = merge(
    module.labels.tags,
    var.db_parameter_group_tags,
    {
      "Name" = format("%s%sparameter", module.labels.id, var.delimiter)
    }
  )
  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_db_option_group" "db_option_group" {
  count = var.enabled && var.option_group_enabled && (var.option_group_name == "") ? 1 : 0

  provider                 = aws.stack
  name                     = format("%s-option-grp", module.labels.id)
#  name_prefix              = format("subnet%s%s", module.labels.id, var.delimiter)
  option_group_description = format("Option group for %s", module.labels.id)
  engine_name              = var.engine_name
  major_engine_version     = var.major_engine_version

  dynamic "option" {
    for_each = var.options
    content {
      option_name                    = option.value.option_name
      port                           = lookup(option.value, "port", null)
      version                        = lookup(option.value, "version", null)
      db_security_group_memberships  = lookup(option.value, "db_security_group_memberships", null)
      vpc_security_group_memberships = lookup(option.value, "vpc_security_group_memberships", null)

      dynamic "option_settings" {
        for_each = lookup(option.value, "option_settings", [])
        content {
          name  = lookup(option_settings.value, "name", null)
          value = lookup(option_settings.value, "value", null)
        }
      }
    }
  }

  tags = merge(
    module.labels.tags,
    var.db_option_group_tags,
    {
      "Name" = format("%s%soption-group", module.labels.id, var.delimiter)
    }
  )

  timeouts {
    delete = lookup(var.timeouts, "delete", null)
  }

  lifecycle {
    create_before_destroy = true
  }
}


################################################################################
# CloudWatch Log Group
################################################################################

# Log groups will not be enabledd if using an identifier prefix
resource "aws_cloudwatch_log_group" "this" {
  for_each = toset([for log in var.enabled_cloudwatch_logs_exports : log if var.enabled && var.enabled_cloudwatch_log_group && !var.use_identifier_prefix])

  provider          = aws.stack
  name              = "/aws/rds/instance/${module.labels.id}/${each.value}"
  retention_in_days = var.cloudwatch_log_group_retention_in_days
  kms_key_id        = var.cloudwatch_log_group_kms_key_id

  tags = merge(
    module.labels.tags,
    var.cloudwatch_log_group_tags
  )
}

################################################################################
# Enhanced monitoring
################################################################################

data "aws_iam_policy_document" "enhanced_monitoring" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "Service"
      identifiers = ["monitoring.rds.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "enhanced_monitoring" {
  count = var.enabled_monitoring_role ? 1 : 0

  provider = aws.stack
  name     = module.labels.id
  //  name_prefix          = local.monitoring_role_name_prefix
  assume_role_policy   = data.aws_iam_policy_document.enhanced_monitoring.json
  description          = var.monitoring_role_description
  permissions_boundary = var.monitoring_role_permissions_boundary

  tags = merge(
    {
      "Name" = format("%s", var.monitoring_role_name)
    },
    module.labels.tags,
    var.mysql_iam_role_tags
  )
}

resource "aws_iam_role_policy_attachment" "enhanced_monitoring" {
  count = var.enabled_monitoring_role ? 1 : 0

  provider   = aws.stack
  role       = aws_iam_role.enhanced_monitoring[0].name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}


resource "aws_db_instance" "this" {
  count = var.enabled && var.enabled_read_replica ? 1 : 0

  provider          = aws.stack
  identifier        = module.labels.id
  identifier_prefix = local.identifier_prefix

  engine            = local.engine
  engine_version    = local.engine_version
  instance_class    = var.instance_class
  allocated_storage = var.allocated_storage
  storage_type      = var.storage_type
  storage_encrypted = var.storage_encrypted
  kms_key_id        = var.kms_key_id
  license_model     = var.license_model

  db_name                             = var.db_name
  username                            = local.username
  password                            = local.password
  port                                = var.port
  domain                              = var.domain
  domain_iam_role_name                = var.domain_iam_role_name
  iam_database_authentication_enabled = var.iam_database_authentication_enabled
  custom_iam_instance_profile         = var.custom_iam_instance_profile

  vpc_security_group_ids = var.vpc_security_group_ids
  db_subnet_group_name   = local.db_subnet_group_name
  parameter_group_name   = var.parameter_group_name != null ? var.parameter_group_name : aws_db_parameter_group.main[0].name
  network_type           = var.network_type
  option_group_name = var.option_group_name != "" ? var.option_group_name : var.option_group_enabled && (var.option_group_name == "") ? aws_db_option_group.db_option_group[0].id : null
  availability_zone   = var.availability_zone
  multi_az            = var.multi_az
  iops                = var.iops
  storage_throughput  = var.storage_throughput
  publicly_accessible = var.publicly_accessible
  ca_cert_identifier  = var.ca_cert_identifier

  allow_major_version_upgrade = var.allow_major_version_upgrade
  auto_minor_version_upgrade  = var.auto_minor_version_upgrade
  apply_immediately           = var.apply_immediately
  maintenance_window          = var.maintenance_window

  # https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/blue-green-deployments.html
  dynamic "blue_green_update" {
    for_each = length(var.blue_green_update) > 0 ? [var.blue_green_update] : []

    content {
      enabled = try(blue_green_update.value.enabled, null)
    }
  }

  snapshot_identifier       = var.snapshot_identifier
  copy_tags_to_snapshot     = var.copy_tags_to_snapshot
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = module.labels.id

  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_retention_period = var.performance_insights_enabled ? var.performance_insights_retention_period : null
  performance_insights_kms_key_id       = var.performance_insights_enabled ? var.performance_insights_kms_key_id : null

  replicate_source_db     = var.replicate_source_db
  replica_mode            = var.replica_mode
  backup_retention_period = length(var.blue_green_update) > 0 ? coalesce(var.backup_retention_period, 1) : var.backup_retention_period
  backup_window           = var.backup_window
  max_allocated_storage   = var.max_allocated_storage
  monitoring_interval     = var.monitoring_interval
  monitoring_role_arn     = join("", aws_iam_role.enhanced_monitoring.*.arn)

  character_set_name              = var.character_set_name
  timezone                        = var.timezone
  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports

  deletion_protection      = var.deletion_protection
  delete_automated_backups = var.delete_automated_backups

  dynamic "restore_to_point_in_time" {
    for_each = var.restore_to_point_in_time != null ? [var.restore_to_point_in_time] : []

    content {
      restore_time                             = lookup(restore_to_point_in_time.value, "restore_time", null)
      source_db_instance_automated_backups_arn = lookup(restore_to_point_in_time.value, "source_db_instance_automated_backups_arn", null)
      source_db_instance_identifier            = lookup(restore_to_point_in_time.value, "source_db_instance_identifier", null)
      source_dbi_resource_id                   = lookup(restore_to_point_in_time.value, "source_dbi_resource_id", null)
      use_latest_restorable_time               = lookup(restore_to_point_in_time.value, "use_latest_restorable_time", null)
    }
  }

  dynamic "s3_import" {
    for_each = var.s3_import != null ? [var.s3_import] : []

    content {
      source_engine         = "mysql"
      source_engine_version = s3_import.value.source_engine_version
      bucket_name           = s3_import.value.bucket_name
      bucket_prefix         = lookup(s3_import.value, "bucket_prefix", null)
      ingestion_role        = s3_import.value.ingestion_role
    }
  }

  tags = merge(
    module.labels.tags,
    var.db_instance_this_tags
  )

  depends_on = [aws_cloudwatch_log_group.this]

  timeouts {
    create = lookup(var.timeouts, "create", null)
    delete = lookup(var.timeouts, "delete", null)
    update = lookup(var.timeouts, "update", null)
  }
  lifecycle {
    ignore_changes = [password]
  }
}


resource "aws_db_instance" "read" {
  count = var.enabled && var.enabled_read_replica && var.enabled_replica ? 1 : 0

  provider          = aws.stack
  identifier        = format("%s-replica", module.labels.id)
  identifier_prefix = local.identifier_prefix

  engine            = null
  engine_version    = null
  instance_class    = var.replica_instance_class
  allocated_storage = null
  storage_type      = var.storage_type
  storage_encrypted = var.storage_encrypted
  kms_key_id        = var.kms_key_id
  license_model     = var.license_model

  db_name                             = null
  username                            = null
  password                            = local.password
  port                                = var.port
  domain                              = var.domain
  domain_iam_role_name                = var.domain_iam_role_name
  iam_database_authentication_enabled = var.iam_database_authentication_enabled
  custom_iam_instance_profile         = var.custom_iam_instance_profile

  vpc_security_group_ids = var.vpc_security_group_ids
  db_subnet_group_name   = null
  parameter_group_name   = var.parameter_group_name != null ? var.parameter_group_name : aws_db_parameter_group.main[0].name
  network_type           = var.network_type
  option_group_name = var.option_group_name != "" ? var.option_group_name : var.option_group_enabled && (var.option_group_name == "") ? aws_db_option_group.db_option_group[0].id : null
  availability_zone   = var.availability_zone
  multi_az            = var.multi_az
  iops                = var.iops
  storage_throughput  = var.storage_throughput
  publicly_accessible = var.publicly_accessible
  ca_cert_identifier  = var.ca_cert_identifier

  allow_major_version_upgrade = var.allow_major_version_upgrade
  auto_minor_version_upgrade  = var.auto_minor_version_upgrade
  apply_immediately           = var.apply_immediately
  maintenance_window          = var.maintenance_window

  # https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/blue-green-deployments.html
  dynamic "blue_green_update" {
    for_each = length(var.blue_green_update) > 0 ? [var.blue_green_update] : []

    content {
      enabled = try(blue_green_update.value.enabled, null)
    }
  }

  snapshot_identifier       = var.snapshot_identifier
  copy_tags_to_snapshot     = var.copy_tags_to_snapshot
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = local.final_snapshot_identifier

  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_retention_period = var.performance_insights_enabled ? var.performance_insights_retention_period : null
  performance_insights_kms_key_id       = var.performance_insights_enabled ? var.performance_insights_kms_key_id : null

  replicate_source_db     = join("", aws_db_instance.this.*.identifier)
  replica_mode            = var.replica_mode
  backup_retention_period = length(var.blue_green_update) > 0 ? coalesce(var.backup_retention_period, 1) : var.backup_retention_period
  backup_window           = var.backup_window
  max_allocated_storage   = var.max_allocated_storage
  monitoring_interval     = var.monitoring_interval
  monitoring_role_arn     = join("", aws_iam_role.enhanced_monitoring.*.arn)

  character_set_name              = var.character_set_name
  timezone                        = var.timezone
  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports

  deletion_protection      = var.deletion_protection
  delete_automated_backups = var.delete_automated_backups

  dynamic "restore_to_point_in_time" {
    for_each = var.restore_to_point_in_time != null ? [var.restore_to_point_in_time] : []

    content {
      restore_time                             = lookup(restore_to_point_in_time.value, "restore_time", null)
      source_db_instance_automated_backups_arn = lookup(restore_to_point_in_time.value, "source_db_instance_automated_backups_arn", null)
      source_db_instance_identifier            = lookup(restore_to_point_in_time.value, "source_db_instance_identifier", null)
      source_dbi_resource_id                   = lookup(restore_to_point_in_time.value, "source_dbi_resource_id", null)
      use_latest_restorable_time               = lookup(restore_to_point_in_time.value, "use_latest_restorable_time", null)
    }
  }

  dynamic "s3_import" {
    for_each = var.s3_import != null ? [var.s3_import] : []

    content {
      source_engine         = "mysql"
      source_engine_version = s3_import.value.source_engine_version
      bucket_name           = s3_import.value.bucket_name
      bucket_prefix         = lookup(s3_import.value, "bucket_prefix", null)
      ingestion_role        = s3_import.value.ingestion_role
    }
  }

  tags = merge(
    module.labels.tags,
    var.db_instance_read_tags
  )

  depends_on = [aws_cloudwatch_log_group.this]

  timeouts {
    create = lookup(var.timeouts, "create", null)
    delete = lookup(var.timeouts, "delete", null)
    update = lookup(var.timeouts, "update", null)
  }
}
