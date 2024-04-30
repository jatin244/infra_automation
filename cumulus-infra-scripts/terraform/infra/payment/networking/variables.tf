#####################################provider##########################
variable "ops_assume_role_arn" {
}
variable "intercom_role_arn" {
}
variable "stack_role_arn" {
}

##################################################################

variable "full_enabled" {
  default = true
}
variable "networking_enabled" {
  default = false
}

#####################################local##########################

variable "creds_profile" {
  default = "default"
}
variable "ops_vpc_id" {
}
variable "dns_vpc_id" {
}
variable "common_tags" {
  default = {}
}
variable "transit_gateway_id" {
}
variable "transit_gateway_spoke_rtb_id" {
}
variable "transit_gateway_spoke_int_id" {
}
variable "egress_vpc_public_rtb_id" {
}
variable "ingress_vpc_public_rtb_id" {
}
variable "ingress_vpc_id" {
}
variable "ingress_vpc_cidr" {
}
variable "ops_vpc_cidr" {
}
variable "hosted_zone_name" {
}

variable "application_private_subnet_tags" {
  default = {}
}
#########################################################

variable "region" {
  default = "us-east-1"
}
variable "environment" {
}
variable "managedby" {
  default = "IDC Cloud Services"
}
variable "label_order" {
  default = ["environment", "name"]
}
variable "product" {
  default = "vtx"
}
variable "data_vpc_id" {
  default = ""
}
variable "application_vpc_id" {
  default = ""
}
variable "data_vpc_cidr" {
}
variable "application_vpc_cidr" {
}
variable "data_private_route_tables" {
}
variable "data_private_subnets" {
}
variable "data_msk_private_subnets" {
}
variable "application_private_subnets" {
}
variable "application_private_route_tables" {
}
variable "data_EIPs" {
  default = {}
}
variable "data_NATs" {
  default = {}
}
variable "data_public_route_tables" {
  default = {}
}
variable "data_public_subnets" {
  default = {}
}
variable "application_EIPs" {
  default = {}
}
variable "application_NATs" {
  default = {}
}
variable "application_public_route_tables" {
  default = {}
}
variable "application_public_subnets" {
  default = {}
}
variable "data_vpc_enabled" {
  default = true
}
variable "application_vpc_enabled" {
  default = true
}
variable "route53_resolver_rule_id" {
}
variable "hosted_zone_id" {
}
variable "data_vpc_route53_zone_enabled" {
  default = true
}
variable "application_vpc_route53_zone_enabled" {
  default = true
}
variable "resolver_enabled" {
  default = true
}

##############################peering########################

variable "peering_enabled" {
  default = true
}
variable "peering_connection_name" {
  default = "data-application"
}
variable "different_account" {
  default = false
}
variable "peering_account_id" {
  default = ""
}

###############################s3############################

variable "vpc_flow_log_s3" {
}
#variable "s3_log_bucket_enabled" {
#  default = true
#}
#variable "s3_force_destroy" {
#  default = true
#}
#variable "s3_attributes" {
#  default = ["private"]
#}
#variable "s3_versioning" {
#  default = true
#}
#variable "s3_acl" {
#  default = "private"
#}
