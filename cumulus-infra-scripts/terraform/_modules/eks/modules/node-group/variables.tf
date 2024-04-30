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

variable "application_vpc_enabled" {
  default = ""
}
variable "application_vpc_id" {
  default = ""
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

variable "extra_tags" {
  type        = map(any)
  default     = {}
  description = "Additional tags (e.g. map(`BusinessUnit`,`XYZ`)."
}

variable "managedby" {
  type        = string
  default     = "IDC Cloud Services"
  description = "ManagedBy, eg 'pps'."
}

variable "delimiter" {
  type        = string
  default     = "-"
  description = "Delimiter to be used between `organization`, `environment`, `name` and `attributes`."
}

variable "enabled" {
  type        = bool
  default     = true
  description = "Whether to create the resources. Set to `false` to prevent the module from creating any resources."
}

variable "cluster_name" {
  type        = string
  default     = ""
  description = "The name of the EKS cluster."
}

variable "aws_iam_instance_profile_name" {
  type        = string
  default     = ""
  description = "The name of the existing instance profile that will be used in autoscaling group for EKS workers. If empty will create a new instance profile."
}
variable "volume_size" {
  type        = number
  default     = 20
  description = "The size of ebs volume."
}

variable "volume_type" {
  type        = string
  default     = "standard"
  description = "The type of volume. Can be `standard`, `gp2`, or `io1`. (Default: `standard`)."
}

variable "node_group_enabled" {
  type        = bool
  default     = false
  description = "Enabling or disabling the node group."
}

variable "node_security_group_ids" {
  type        = list(string)
  default     = []
  description = "Set of EC2 Security Group IDs to allow SSH access (port 22) from on the worker nodes."
}


#variable "ami_release_version" {
#  type        = string
#  description = "AMI version of the EKS Node Group. Defaults to latest version for Kubernetes version"
#}

variable "subnet_ids" {
  type        = list(string)
  default     = []
  description = "A list of subnet IDs to launch resources in EKS."
}

variable "key_name" {
  type        = string
  default     = ""
  description = "SSH key name that should be used for the instance."
}

variable "kubernetes_version" {
  type        = string
  description = "Kubernetes version. Defaults to EKS Cluster Kubernetes version. Terraform will only perform drift detection if a configuration value is provided"
}

variable "enable_cluster_autoscaler" {
  type        = bool
  default     = false
  description = "Whether to enable node group to scale the Auto Scaling Group"
}

variable "module_depends_on" {
  type        = any
  default     = null
  description = "Can be any value desired. Module will wait for this value to be computed before creating node group."
}

variable "before_cluster_joining_userdata" {
  type        = string
  default     = ""
  description = "Additional commands to execute on each worker node before joining the EKS cluster (before executing the `bootstrap.sh` script). For more info, see https://kubedex.com/90-days-of-aws-eks-in-production"
}

variable "node_role_arn" {
  type        = string
  default     = ""
  description = "ARN of role profile."
}

variable "node_groups" {
  description = "Node group configurations"
  type = map(object({
    node_group_name           = string
    node_group_instance_type = string
    kubernetes_labels         = map(string)
    taints = list(object({
      taint_key    = string
      taint_value  = string
      taint_effect = string
    }))
    node_group_capacity_type  = string
    ami_type                  = string
    ami_release_version       = string
    node_group_volume_size    = number
    node_group_desired_size   = number
    node_group_max_size       = number
    node_group_min_size       = number
    node_group_volume_type    = string
    subnet_component_tag      = string
  }))
}

variable "resources_to_tag" {
  type        = list(string)
  description = "List of auto-launched resource types to tag. Valid types are \"instance\", \"volume\", \"elastic-gpu\", \"spot-instances-request\"."
  default     = []
  validation {
    condition = (
      length(compact([for r in var.resources_to_tag : r if !contains(["instance", "volume", "elastic-gpu", "spot-instances-request"], r)])) == 0
    )
    error_message = "Invalid resource type in `resources_to_tag`. Valid types are \"instance\", \"volume\", \"elastic-gpu\", \"spot-instances-request\"."
  }
}

variable "ebs_encryption" {
  type        = bool
  default     = false
  description = "Enables EBS encryption on the volume (Default: false). Cannot be used with snapshot_id."
}

variable "kms_key_arn" {
  type        = string
  default     = ""
  description = "AWS Key Management Service (AWS KMS) customer master key (CMK) to use when creating the encrypted volume. encrypted must be set to true when this is set."
}

variable "environ" {
  type        = string
  default     = "vtxops"
  description = "The Name of environ"
}
variable "product" {
  type        = string
  default     = "vtx"
  description = "The Name of product"
}

