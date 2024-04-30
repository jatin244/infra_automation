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

##########################helm_release####################################

variable "helm_release_aws_node_termination_handler_enabled" {
  default = true
}
variable "helm_release_application_enabled" {
  default = true
}
variable "helm_release_kube_state_metrics_enabled" {
  default = true
}
variable "helm_release_metrics_server_enabled" {
  default = true
}
variable "helm_release_albingress_enabled" {
  default = true
}

##########################eks####################################

variable "eks_enabled" {
  default = true
}
variable "environment" {
}
variable "management_node_group_identifier" {
}
variable "region" {
  default = "us-east-1"
}
variable "application_vpc_id" {
  default = ""
}
variable "application_vpc_enabled" {
  default = true
}
