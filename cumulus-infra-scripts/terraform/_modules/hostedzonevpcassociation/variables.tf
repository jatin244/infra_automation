variable "vpc" {
  type    = string
  default = ""
}

variable "hostedzone" {
  type    = string
  default = ""
}
variable "route53_zone_enabled" {
  type        = bool
  default     = true
  description = "Flag to control the kms creation."
}