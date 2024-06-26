#Module      : LABEL
#Description : Terraform label module variables
variable "name" {
  type        = string
  default     = ""
  description = "Name  (e.g. `app` or `cluster`)."
}

variable "repository" {
  type        = string
  default     = "AWS Account glb-cbdp codecommit repository"
  description = "Terraform current module repo"
}


variable "environment" {
  type        = string
  default     = "test"
  description = "Environment (e.g. `prod`, `dev`, `staging`)."
}

variable "label_order" {
  type        = list(any)
  default     = ["name", "environment"]
  description = "Label order, e.g. `name`,`application`."
}

variable "managedby" {
  type        = string
  default     = "IDC Cloud Services"
  description = "ManagedBy, eg 'pps'."
}

variable "extra_tags" {
  type        = map(string)
  default     = {}
  description = "Additional tags (e.g. map(`BusinessUnit`,`XYZ`)."
}

# Module      : ALB
# Description : Terraform ALB module variables.

variable "instance_count" {
  type        = number
  default     = 0
  description = "The count of instances."
}

variable "internal" {
  type        = string
  default     = ""
  description = "If true, the LB will be internal."
}

variable "load_balancer_type" {
  type        = string
  default     = ""
  description = "The type of load balancer to create. Possible values are application or network. The default value is application."
  sensitive   = true
}


variable "subnet_mapping" {
  default     = []
  type        = list(map(string))
  description = "A list of subnet mapping blocks describing subnets to attach to network load balancer"
}

variable "https_listeners" {
  type        = list(map(string))
  default     = []
  description = "A list of maps describing the HTTPS listeners for this ALB. Required key/values: port, certificate_arn. Optional key/values: ssl_policy (defaults to ELBSecurityPolicy-2016-08), target_group_index (defaults to 0)"
}

variable "http_tcp_listeners" {
  description = "A list of maps describing the HTTP listeners for this ALB. Required key/values: port, protocol. Optional key/values: target_group_index (defaults to 0)"
  type        = list(map(string))
  default     = []
  sensitive   = true
}

variable "target_groups" {
  description = "A list of maps containing key/value pairs that define the target groups to be created. Order of these maps is important and the index of these are to be referenced in listener definitions. Required key/values: name, backend_protocol, backend_port. Optional key/values are in the target_groups_defaults variable."
  type        = any
  default     = []
}

variable "security_groups" {
  type        = list(any)
  default     = []
  description = "A list of security group IDs to assign to the LB. Only valid for Load Balancers of type application."
}

variable "subnets" {
  type        = list(any)
  default     = []
  description = "A list of subnet IDs to attach to the LB. Subnets cannot be updated for Load Balancers of type network. Changing this value will for load balancers of type network will force a recreation of the resource."
  sensitive   = true
}

variable "enable_deletion_protection" {
  type        = bool
  default     = false
  description = "If true, deletion of the load balancer will be disabled via the AWS API. This will prevent Terraform from deleting the load balancer. Defaults to false."
}

variable "https_port" {
  type        = number
  default     = 443
  description = "The port on which the load balancer is listening. like 80 or 443."
  sensitive   = true
}

variable "listener_protocol" {
  type        = string
  default     = "HTTPS"
  description = "The protocol for connections from clients to the load balancer. Valid values are TCP, HTTP and HTTPS. Defaults to HTTP."
  sensitive   = true
}

variable "http_port" {
  type        = number
  default     = 80
  description = "The port on which the load balancer is listening. like 80 or 443."
  sensitive   = true
}

variable "https_enabled" {
  type        = bool
  default     = true
  description = "A boolean flag to enable/disable HTTPS listener."
}

variable "http_enabled" {
  type        = bool
  default     = true
  description = "A boolean flag to enable/disable HTTP listener."
}

variable "listener_type" {
  type        = string
  default     = "forward"
  description = "The type of routing action. Valid values are forward, redirect, fixed-response, authenticate-cognito and authenticate-oidc."
}


variable "listener_certificate_arn" {
  type        = string
  sensitive   = true
  default     = ""
  description = "The ARN of the SSL server certificate. Exactly one certificate is required if the protocol is HTTPS."
}

variable "target_group_port" {
  type        = string
  default     = 80
  description = "The port on which targets receive traffic, unless overridden when registering a specific target."
}

variable "vpc_id" {
  type        = string
  sensitive   = true
  default     = ""
  description = "The identifier of the VPC in which to create the target group."
}

variable "target_id" {
  type        = list(any)
  description = "The ID of the target. This is the Instance ID for an instance, or the container ID for an ECS container. If the target type is ip, specify an IP address."
}

variable "idle_timeout" {
  type        = number
  default     = 60
  description = "The time in seconds that the connection is allowed to be idle."
}

variable "enable_cross_zone_load_balancing" {
  type        = bool
  default     = true
  description = "Indicates whether cross zone load balancing should be enabled in application load balancers."
}

variable "enable_http2" {
  type        = bool
  default     = true
  description = "Indicates whether HTTP/2 is enabled in application load balancers."
}

variable "ip_address_type" {
  type        = string
  sensitive   = true
  default     = "ipv4"
  description = "The type of IP addresses used by the subnets for your load balancer. The possible values are ipv4 and dualstack."
}

variable "log_bucket_name" {
  type        = string
  default     = ""
  description = "S3 bucket (externally created) for storing load balancer access logs. Required if logging_enabled is true."
}

variable "load_balancer_create_timeout" {
  type        = string
  default     = "10m"
  description = "Timeout value when creating the ALB."
}

variable "load_balancer_delete_timeout" {
  type        = string
  default     = "10m"
  description = "Timeout value when deleting the ALB."
}

variable "load_balancer_update_timeout" {
  type        = string
  default     = "10m"
  description = "Timeout value when updating the ALB."
}


variable "http_listener_type" {
  type        = string
  default     = "redirect"
  description = "The type of routing action. Valid values are forward, redirect, fixed-response, authenticate-cognito and authenticate-oidc."
}

variable "status_code" {
  type        = string
  default     = "HTTP_301"
  description = " The HTTP redirect code. The redirect is either permanent (HTTP_301) or temporary (HTTP_302)."
}

variable "enable" {
  type        = bool
  default     = false
  description = "If true, create alb."
}

variable "clb_enable" {
  type        = bool
  default     = false
  description = "If true, create clb."
}

variable "listeners" {
  default = []
  type = list(object({
    lb_port : number
    lb_protocol : string
    instance_port : number
    instance_protocol : string
    ssl_certificate_id : string
  }))
  description = "A list of listener configurations for the ELB."
}

variable "connection_draining_timeout" {
  type        = number
  default     = 300
  description = "The time after which connection draining is aborted in seconds."
}

variable "connection_draining" {
  type        = bool
  default     = false
  description = "TBoolean to enable connection draining. Default: false."
}

variable "health_check_target" {
  description = "The target to use for health checks."
  type        = string
  default     = "TCP:80"
}

variable "health_check_timeout" {
  type        = number
  default     = 5
  description = "The time after which a health check is considered failed in seconds."
}

variable "health_check_interval" {
  description = "The time between health check attempts in seconds."
  type        = number
  default     = 30
}

variable "health_check_unhealthy_threshold" {
  type        = number
  default     = 2
  description = "The number of failed health checks before an instance is taken out of service."
}

variable "health_check_healthy_threshold" {
  type        = number
  default     = 10
  description = "The number of successful health checks before an instance is put into service."
}

variable "target_type" {
  type        = string
  default     = ""
  description = "The type of target that you must specify when registering targets with this target group."
}

variable "access_logs" {
  type        = bool
  default     = false
  description = "Access logs Enable or Disable."
}

variable "listener_https_fixed_response" {
  description = "Have the HTTPS listener return a fixed response for the default action."
  type = object({
    content_type = string
    message_body = string
    status_code  = string
  })
  default = null
}

variable "with_target_group" {
  type        = bool
  default     = true
  description = "Create LoadBlancer without target group"
}