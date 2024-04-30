terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      configuration_aliases = [aws.stack]
    }
  }
}

resource "aws_route53_zone" "hosted_zone" {
  provider = aws.stack
  name     = var.name == "" ? var.stackCommon.hosted_zone_name : var.name

  lifecycle {
    ignore_changes        = [vpc]
    create_before_destroy = true
  }

  vpc {
    vpc_id = var.stackCommon.ops_vpc_id
  }

  tags = merge(
    tomap({
      "Name" = "${var.name}-hostedzone"
    }),
    var.stackCommon.common_tags
  )
}

output "hosted_zone" {
  value = aws_route53_zone.hosted_zone
}
