terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      configuration_aliases = [aws.stack]
    }
  }
}
##-----------------------------------------------------------------------------
## Labels module callled that will be used for naming and tags.
##-----------------------------------------------------------------------------
module "labels" {
  source = "../labels"

  name        = var.name
  environment = var.environment
  managedby   = var.managedby
  label_order = var.label_order
  extra_tags  = var.extra_tags

}

##-----------------------------------------------------------------------------
## A load balancer serves as the single point of contact for clients. The load balancer distributes incoming application traffic across multiple targets.
##-----------------------------------------------------------------------------
resource "aws_lb" "main" {
  provider                         = aws.stack
  count                            = var.enable ? 1 : 0
  name                             = module.labels.id
  internal                         = var.internal
  load_balancer_type               = var.load_balancer_type
  security_groups                  = var.security_groups
  subnets                          = var.subnets
  enable_deletion_protection       = var.enable_deletion_protection
  idle_timeout                     = var.idle_timeout
  enable_cross_zone_load_balancing = var.enable_cross_zone_load_balancing
  enable_http2                     = var.enable_http2
  ip_address_type                  = var.ip_address_type
  tags                             = module.labels.tags
  drop_invalid_header_fields       = true

  timeouts {
    create = var.load_balancer_create_timeout
    delete = var.load_balancer_delete_timeout
    update = var.load_balancer_update_timeout
  }
  access_logs {
    enabled = var.access_logs
    bucket  = var.log_bucket_name
    prefix  = module.labels.id
  }
  dynamic "subnet_mapping" {
    for_each = var.subnet_mapping

    content {
      subnet_id            = subnet_mapping.value.subnet_id
      allocation_id        = lookup(subnet_mapping.value, "allocation_id", null)
      private_ipv4_address = lookup(subnet_mapping.value, "private_ipv4_address", null)
      ipv6_address         = lookup(subnet_mapping.value, "ipv6_address", null)
    }
  }
}

##-----------------------------------------------------------------------------
## A listener is a process that checks for connection requests.
## It is configured with a protocol and a port for front-end (client to load balancer) connections, and a protocol and a port for back-end (load balancer to back-end instance) connections.
##-----------------------------------------------------------------------------
resource "aws_lb_listener" "https" {
  provider = aws.stack
  count    = var.enable == true && var.with_target_group && var.https_enabled == true && var.load_balancer_type == "application" ? 1 : 0

  load_balancer_arn = element(aws_lb.main[*].arn, count.index)
  port              = var.https_port
  protocol          = var.listener_protocol
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-Ext-2018-06"
  certificate_arn   = var.listener_certificate_arn
  default_action {
    target_group_arn = join("", aws_lb_target_group.main[*].arn)
    type             = var.listener_type

    dynamic "fixed_response" {
      for_each = var.listener_https_fixed_response != null ? [var.listener_https_fixed_response] : []
      content {
        content_type = fixed_response.value["content_type"]
        message_body = fixed_response.value["message_body"]
        status_code  = fixed_response.value["status_code"]
      }
    }
  }
}

##-----------------------------------------------------------------------------
## A listener is a process that checks for connection requests.
## It is configured with a protocol and a port for front-end (client to load balancer) connections, and a protocol and a port for back-end (load balancer to back-end instance) connections.
##-----------------------------------------------------------------------------
resource "aws_lb_listener" "http" {
  provider = aws.stack
  count    = var.enable == true && var.with_target_group && var.http_enabled == true && var.load_balancer_type == "application" ? 1 : 0

  load_balancer_arn = element(aws_lb.main[*].arn, count.index)
  port              = var.http_port
  protocol          = "HTTP"
  default_action {
    target_group_arn = element(aws_lb_target_group.main[*].arn, count.index)
    type             = var.http_listener_type
    redirect {
      port        = var.https_port
      protocol    = var.listener_protocol
      status_code = var.status_code
    }
  }
}

##-----------------------------------------------------------------------------
## A listener is a process that checks for connection requests.
## It is configured with a protocol and a port for front-end (client to load balancer) connections, and a protocol and a port for back-end (load balancer to back-end instance) connections.
##-----------------------------------------------------------------------------
resource "aws_lb_listener" "nhttps" {
  provider = aws.stack
  count    = var.enable == true && var.with_target_group && var.https_enabled == true && var.load_balancer_type == "network" ? length(var.https_listeners) : 0

  load_balancer_arn = element(aws_lb.main[*].arn, count.index)
  port              = var.https_listeners[count.index]["port"]
  protocol          = lookup(var.https_listeners[count.index], "protocol", "HTTPS")
  certificate_arn   = var.https_listeners[count.index]["certificate_arn"]
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-Ext-2018-06"
  default_action {
    target_group_arn = aws_lb_target_group.main[var.https_listeners[count.index]["target_group_index"]].arn
    #target_group_arn = element(aws_lb_target_group.main[*].arn, count.index)
    type             = "forward"
  }
}

##-----------------------------------------------------------------------------
## A listener is a process that checks for connection requests.
## It is configured with a protocol and a port for front-end (client to load balancer) connections, and a protocol and a port for back-end (load balancer to back-end instance) connections.
##-----------------------------------------------------------------------------
resource "aws_lb_listener" "nhttp" {
  provider = aws.stack
  count    = var.enable == true && var.with_target_group && var.load_balancer_type == "network" ? length(var.http_tcp_listeners) : 0

  load_balancer_arn = element(aws_lb.main[*].arn, 0)
  port              = var.http_tcp_listeners[count.index]["port"]
  protocol          = var.http_tcp_listeners[count.index]["protocol"]
  default_action {
    target_group_arn = aws_lb_target_group.main[var.http_tcp_listeners[count.index]["target_group_index"]].arn
   # target_group_arn = element(aws_lb_target_group.main[*].arn, count.index)
    type             = "forward"
  }
}

##-----------------------------------------------------------------------------
## aws_lb_target_group. Provides a Target Group resource for use with Load Balancer resources.
##-----------------------------------------------------------------------------
resource "aws_lb_target_group" "main" {
  provider                           = aws.stack
  count                              = var.enable && var.with_target_group ? length(var.target_groups) : 0
  name                               = format("%s-%s-TG", module.labels.id, var.target_groups[count.index].backend_port)
  port                               = lookup(var.target_groups[count.index], "backend_port", null)
  protocol                           = lookup(var.target_groups[count.index], "backend_protocol", null) != null ? upper(lookup(var.target_groups[count.index], "backend_protocol")) : null
  vpc_id                             = var.vpc_id
  target_type                        = lookup(var.target_groups[count.index], "target_type", null)
  deregistration_delay               = lookup(var.target_groups[count.index], "deregistration_delay", null)
  slow_start                         = lookup(var.target_groups[count.index], "slow_start", null)
  proxy_protocol_v2                  = lookup(var.target_groups[count.index], "proxy_protocol_v2", null)
  lambda_multi_value_headers_enabled = lookup(var.target_groups[count.index], "lambda_multi_value_headers_enabled", null)
  preserve_client_ip                 = lookup(var.target_groups[count.index], "preserve_client_ip", null)
  load_balancing_algorithm_type      = lookup(var.target_groups[count.index], "load_balancing_algorithm_type", null)
  dynamic "health_check" {
    for_each = length(keys(lookup(var.target_groups[count.index], "health_check", {}))) == 0 ? [] : [lookup(var.target_groups[count.index], "health_check", {})]

    content {
      enabled             = lookup(health_check.value, "enabled", null)
      interval            = lookup(health_check.value, "interval", null)
      path                = lookup(health_check.value, "path", null)
      port                = lookup(health_check.value, "port", null)
      healthy_threshold   = lookup(health_check.value, "healthy_threshold", null)
      unhealthy_threshold = lookup(health_check.value, "unhealthy_threshold", null)
      timeout             = lookup(health_check.value, "timeout", null)
      protocol            = lookup(health_check.value, "protocol", null)
      matcher             = lookup(health_check.value, "matcher", null)
    }
  }

  dynamic "stickiness" {
    for_each = length(keys(lookup(var.target_groups[count.index], "stickiness", {}))) == 0 ? [] : [lookup(var.target_groups[count.index], "stickiness", {})]
    content {
      enabled         = lookup(stickiness.value, "enabled", null)
      cookie_duration = lookup(stickiness.value, "cookie_duration", null)
      type            = lookup(stickiness.value, "type", null)
    }
  }
}

##-----------------------------------------------------------------------------
## For attaching resources with Elastic Load Balancer (ELB), see the aws_elb_attachment resource.
##-----------------------------------------------------------------------------
resource "aws_lb_target_group_attachment" "attachment" {
  provider = aws.stack
  count    = var.enable && var.with_target_group && var.load_balancer_type == "application" && var.target_type == "" ? var.instance_count : 0

  target_group_arn = element(aws_lb_target_group.main[*].arn, count.index)
  target_id        = element(var.target_id, count.index)
  port             = var.target_group_port
}

locals {
  arns    = aws_lb_target_group.main.*.arn
  targets = range(var.instance_count)
  ports   = [for d in var.target_groups : d.backend_port]
  # Nested loop over both lists, and flatten the result.
  arns_targets = distinct(flatten([
    for arn_key, arn in var.target_groups : [
      for target in local.targets : {
        target = target
        port   = var.target_groups[tonumber(arn_key)].backend_port
        key    = tonumber(arn_key)
      }
    ]
  ]))
}

resource "aws_lb_target_group_attachment" "nattachment" {
  provider = aws.stack
  for_each = var.load_balancer_type == "network" && var.enable && var.with_target_group ? { for k, v in local.arns_targets : k => v } : {}

  target_group_arn = element(aws_lb_target_group.main.*.arn, each.value.key) #local.arns_targets[count.index].arn
  target_id        = var.target_id[each.value.target]                        #each.value.target
  port             = each.value.port
}

##-----------------------------------------------------------------------------
## Elastic Load Balancing (ELB) automatically distributes incoming application traffic across multiple targets and virtual appliances in one or more Availability Zones (AZs)
##-----------------------------------------------------------------------------
resource "aws_elb" "main" {
  provider = aws.stack
  count    = var.clb_enable && var.load_balancer_type == "classic" == true ? 1 : 0

  name                        = module.labels.id
  instances                   = var.target_id
  internal                    = var.internal
  cross_zone_load_balancing   = var.enable_cross_zone_load_balancing
  idle_timeout                = var.idle_timeout
  connection_draining         = var.connection_draining
  connection_draining_timeout = var.connection_draining_timeout
  security_groups             = var.security_groups
  subnets                     = var.subnets
  dynamic "listener" {
    for_each = var.listeners
    content {
      instance_port      = listener.value.instance_port
      instance_protocol  = listener.value.instance_protocol
      lb_port            = listener.value.lb_port
      lb_protocol        = listener.value.lb_protocol
      ssl_certificate_id = listener.value.ssl_certificate_id
    }
  }

  health_check {
    target              = var.health_check_target
    timeout             = var.health_check_timeout
    interval            = var.health_check_interval
    unhealthy_threshold = var.health_check_unhealthy_threshold
    healthy_threshold   = var.health_check_healthy_threshold
  }
  tags = module.labels.tags
}
