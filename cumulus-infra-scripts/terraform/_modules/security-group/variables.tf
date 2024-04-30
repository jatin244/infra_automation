#Module      : LABEL
#Description : Terraform label module variables.
variable "name" {
  type        = string
  default     = ""
  description = "Name  (e.g. `app` or `cluster`)."
}

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
    ops_region       = string,
    hosted_zone_name = string,
    common_tags      = map(string)
  })
}

variable "SGs" {
  type = list(object({
    name        = string,
    description = string,
    vpc         = string,
  }))
}

variable "SG_Rules" {
  type = list(object({
    security_group_name        = string,
    source_security_group_name = string,
    source_security_group_id   = string,
    type                       = string,
    protocol                   = string,
    from_port                  = number,
    to_port                    = number,
    self                       = bool,
    description                = string,
    cidr_blocks                = list(string),
    prefix_list_ids            = list(string)
  }))
}

variable "base_info" {
  type = map(object({
    vpc_id = string
  }))
}

variable "depends" {
  type    = any
  default = null
}

variable "SG_id_map" {
  type    = map(string)
  default = {}
}

variable "security_enabled" {
  type    = bool
  default = false
}