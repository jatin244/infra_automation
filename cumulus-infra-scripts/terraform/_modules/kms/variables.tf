
variable "stackCommon" {
  type = object({
    creds_profile    = string,
    stack_region     = string,
    stack_name       = string,
    ops_vpc_cidr     = string,
    ops_vpc_id       = string,
    ingress_vpc_id   = string,
    ops_region       = string,
    hosted_zone_name = string,
    common_tags      = map(string)
  })
}

variable "kms" {
  type = object({
    description              = string,
    key_usage                = string,
    customer_master_key_spec = string,
    policy                   = string,
    enable_key_rotation      = string,
    multi_region             = string
  })
}

variable "kms_key_enabled" {
  type        = bool
  default     = true
  description = "Flag to control the kms creation."
}
variable "alias" {
  type        = string
  default     = ""
  description = "The display name of the alias. The name must start with the word `alias` followed by a forward slash."
}