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
variable "peering_enabled" {
  type        = bool
  default     = true
  description = "Environment (e.g. `prod`, `dev`, `staging`)."
}
variable "aws_vpc_peering_connection_accepter_enabled" {
  type        = bool
  default     = true
  description = "Environment (e.g. `prod`, `dev`, `staging`)."
}
variable "aws_vpc_peering_connection_enabled" {
  type        = bool
  default     = true
  description = "Environment (e.g. `prod`, `dev`, `staging`)."
}

variable "label_order" {
  type        = list(any)
  default     = []
  description = "Label order, e.g. `name`,`application`."
}

variable "managedby" {
  type        = string
  default     = "IDC Cloud Services"
  description = "ManagedBy, eg 'pps'."
}

variable "peering" {
  type = object({
    peering_connection_name = string,
    different_account       = bool,
    account_id              = string,
    src_vpc_id              = string,
    dst_vpc_id              = string
  })
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