terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      configuration_aliases = [aws.stack, aws.vpc]
    }
  }
}

resource "aws_route53_vpc_association_authorization" "dns" {
  provider = aws.stack
  count    = var.route53_zone_enabled ? 1 : 0
  vpc_id   = var.vpc
  zone_id  = var.hostedzone
}

resource "aws_route53_zone_association" "vpc_association" {
  provider = aws.vpc
  count    = var.route53_zone_enabled ? 1 : 0
  vpc_id   = var.vpc
  zone_id  = var.hostedzone

  depends_on = [aws_route53_vpc_association_authorization.dns]

}
