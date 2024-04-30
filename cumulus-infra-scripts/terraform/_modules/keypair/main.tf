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

#Module      : KEY PAIR
#Description : Terraform module for generating or importing an SSH public key file into AWS.
resource "aws_key_pair" "default" {
  count = var.enable_key_pair == true ? 1 : 0

  provider   = aws.stack
  key_name   = module.labels.id
  public_key = var.public_key == "" ? file(var.key_path) : var.public_key
  tags       = module.labels.tags
}