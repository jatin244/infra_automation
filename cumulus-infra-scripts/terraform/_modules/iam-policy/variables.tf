#Module      : LABEL
#Description : Terraform label module variables
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

variable "label_order" {
  type        = list(any)
  default     = []
  description = "Label order, e.g. `name`,`application`."
}

variable "attributes" {
  type        = list(any)
  default     = []
  description = "Additional attributes (e.g. `1`)."
}

variable "tags" {
  type        = map(any)
  default     = {}
  description = "Additional tags (e.g. map(`BusinessUnit`,`XYZ`)."
}

variable "managedby" {
  type        = string
  default     = "IDC Cloud Services"
  description = "ManagedBy, eg 'pps'."
}


variable "policy_enabled" {
  type        = bool
  default     = true
  description = "A conditional indicator to enable cluster-autoscale"
}

variable "policy" {
  default     = null
  description = "The policy document."
}

variable "role_name" {
  type        = string
  default     = null
  description = "The Iam Role name."
}
