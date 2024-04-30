output "application-vpc" {
  value       = join("", module.application-vpc.vpc.*.id)
  description = "Application VPC Id."
}

output "data-vpc" {
  value       = join("", module.data-vpc.vpc.*.id)
  description = "Application VPC Id."
}

output "data_vpc_cidr_block" {
  value       = join("", module.data-vpc.vpc.*.cidr_block)
  description = "The CIDR block of the VPC."
}

output "application_vpc_cidr_block" {
  value       = join("", module.application-vpc.vpc.*.cidr_block)
  description = "The CIDR block of the VPC."
}
