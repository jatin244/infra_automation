variable "environment" {
  type        = string
  default     = ""
  description = "Environment (e.g. `prod`, `dev`, `staging`)."
}

variable "stackCommon" {
  type = object({
    creds_profile    = string,
    stack_region     = string,
    stack_name       = string,
    ops_vpc_cidr     = string,
    ops_vpc_id       = string,
    ingress_vpc_id   = string,
    dns_vpc_id       = string,
    ops_region       = string,
    hosted_zone_name = string,
    common_tags      = map(string)
  })
}

variable "name" {
  type    = string
  default = ""
}