variable "vpc" {
  type    = string
  default = ""
}

variable "resolver_rule_id" {
  type    = list(any)
  default = []
}

variable "resolver_enabled" {
  type    = bool
  default = true
}