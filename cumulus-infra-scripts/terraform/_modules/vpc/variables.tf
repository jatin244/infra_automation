variable "environment" {
  type        = string
  default     = ""
  description = "Environment (e.g. `prod`, `dev`, `staging`)."
}

variable "stackCommon" {
  type = object({
    creds_profile                = string,
    stack_region                 = string,
    stack_name                   = string,
    transit_gateway_id           = string,
    transit_gateway_spoke_rtb_id = string,
    transit_gateway_spoke_int_id = string,
    egress_vpc_public_rtb_id     = string,
    ingress_vpc_cidr             = string,
    ingress_vpc_public_rtb_id    = string,
    ops_vpc_cidr                 = string,
    ops_vpc_id                   = string,
    ops_region                   = string,
    hosted_zone_name             = string,
    common_tags                  = map(string)
  })
}


variable "base_infra" {
  type = object({
    eks_cluster_tag = string,
    vpc_name        = string,
    vpc_cidr        = string,
    EIPs = map(object({
      tagName = string,
    })),
    NATs = map(object({
      tagName       = string,
      public_subnet = string,
      elasticIP     = string
    })),
    public_route_tables = map(object({
      tagName = string
    })),
    private_route_tables = map(object({
      tagName = string,
      NAT     = string
    })),
    public_subnets = map(object({
      cidr        = string,
      az_name     = string,
      route_table = string,
      component   = string,
      eks_public_elb = bool
    })),
    private_subnets = map(object({
      cidr        = string,
      az_name     = string,
      route_table = string,
      component   = string,
      eks_internal_elb = bool 
    }))
  })
}

variable "vpc_tags" {
  type    = map(any)
  default = {}
}

variable "internet_gateway_tags" {
  type    = map(any)
  default = {}
}

variable "eip_tags" {
  type    = map(any)
  default = {}
}

variable "nat_gateway_tags" {
  type    = map(any)
  default = {}
}

variable "public_subnet_tags" {
  type    = map(any)
  default = {}
}

variable "private_subnet_tags" {
  type    = map(any)
  default = {}
}

variable "route_table_tags" {
  type    = map(any)
  default = {}
}

variable "tgw_attachment_tags" {
  type    = map(any)
  default = {}
}

variable "enabled" {
  type    = bool
  default = true
}

variable "vpc_centralized" {
  type    = bool
  default = true
}

variable "enable_flow_log" {
  type    = bool
  default = true
}

variable "s3_bucket_arn" {
  type        = string
  default     = ""
  description = "S3 ARN for vpc logs."
}

variable "traffic_type" {
  type        = string
  default     = "ALL"
  description = "Type of traffic to capture. Valid values: ACCEPT,REJECT, ALL."
}
