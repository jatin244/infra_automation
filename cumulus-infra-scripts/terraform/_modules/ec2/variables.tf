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

variable "product" {
  type        = string
  default     = ""
  description = "Environment (e.g. `vtx`, `cpx`, `staging`)."
}

variable "label_order" {
  type        = list(any)
  default     = []
  description = "Label order, e.g. `name`,`application`."
}

variable "extra_tags" {
  type        = map(string)
  default     = {}
  description = "Additional tags (e.g. map(`BusinessUnit`,`XYZ`)."
}

variable "delimiter" {
  type        = string
  default     = "-"
  description = "Delimiter to be used between `organization`, `environment`, `name` and `attributes`."
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

variable "sg_ids" {
  type        = list(any)
  default     = []
  description = "of the security group id."
}

# Module      : EC2 Module
# Description : Terraform EC2 module variables.
variable "ami" {
  type        = string
  default     = ""
  description = "The AMI to use for the instance."
}

variable "ebs_optimized" {
  type        = bool
  default     = false
  description = "If true, the launched EC2 instance will be EBS-optimized."
}

variable "instance_type" {
  type        = string
  description = "The type of instance to start. Updates to this field will trigger a stop/start of the EC2 instance."
}

variable "monitoring" {
  type        = bool
  default     = false
  description = "If true, the launched EC2 instance will have detailed monitoring enabled. (Available since v0.6.0)."
}

variable "associate_public_ip_address" {
  type        = bool
  default     = false
  description = "Associate a public IP address with the instance."
  sensitive   = true
}

variable "ephemeral_block_device" {
  type        = list(any)
  default     = []
  description = "Customize Ephemeral (also known as Instance Store) volumes on the instance."
}

variable "disable_api_termination" {
  type        = bool
  default     = false
  description = "If true, enables EC2 Instance Termination Protection."
}

variable "instance_initiated_shutdown_behavior" {
  type    = string
  default = "terminate"
}

variable "placement_group" {
  type        = string
  default     = ""
  description = "The Placement Group to start the instance in."
}

variable "tenancy" {
  type        = string
  default     = "default"
  description = "The tenancy of the instance (if the instance is running in a VPC). An instance with a tenancy of dedicated runs on single-tenant hardware. The host tenancy is not supported for the import-instance command."
}

variable "root_block_device" {
  type        = list(any)
  default     = []
  description = "Customize details about the root block device of the instance. See Block Devices below for details."
}

variable "user_data" {
  type        = string
  default     = ""
  description = "(Optional) A string of the desired User Data for the ec2."
}

variable "assign_eip_address" {
  type        = bool
  default     = false
  description = "Assign an Elastic IP address to the instance."
  sensitive   = true
}

variable "ebs_device_name" {
  type        = list(string)
  default     = ["/dev/xvdb", "/dev/xvdc", "/dev/xvdd", "/dev/xvde", "/dev/xvdf", "/dev/xvdg", "/dev/xvdh", "/dev/xvdi", "/dev/xvdj", "/dev/xvdk", "/dev/xvdl", "/dev/xvdm", "/dev/xvdn", "/dev/xvdo", "/dev/xvdp", "/dev/xvdq", "/dev/xvdr", "/dev/xvds", "/dev/xvdt", "/dev/xvdu", "/dev/xvdv", "/dev/xvdw", "/dev/xvdx", "/dev/xvdy", "/dev/xvdz"]
  description = "Name of the EBS device to mount."
}

variable "instance_enabled" {
  type        = bool
  default     = true
  description = "Flag to control the instance creation."
}

variable "instance_profile_enabled" {
  type        = bool
  default     = false
  description = "Flag to control the instance profile creation."
}

variable "subnet_ids" {
  type        = list(string)
  default     = []
  description = "A list of VPC Subnet IDs to launch in."
  sensitive   = true
}

variable "instance_count" {
  type        = number
  default     = 0
  description = "Number of instances to launch."
}

variable "source_dest_check" {
  type        = bool
  default     = true
  description = "Controls if traffic is routed to the instance when the destination address does not match the instance. Used for NAT or VPNs."
}

variable "ipv6_address_count" {
  type        = number
  default     = null
  description = "Number of IPv6 addresses to associate with the primary network interface. Amazon EC2 chooses the IPv6 addresses from the range of your subnet."
}

variable "ipv6_addresses" {
  type        = list(any)
  default     = null
  description = "List of IPv6 addresses from the range of the subnet to associate with the primary network interface."
  sensitive   = true
}

variable "network_interface" {
  description = "Customize network interfaces to be attached at instance boot time"
  type        = list(map(string))
  default     = []
}


variable "host_id" {
  type        = string
  default     = null
  description = "The Id of a dedicated host that the instance will be assigned to. Use when an instance is to be launched on a specific dedicated host."
}

variable "cpu_core_count" {
  type        = string
  default     = null
  description = "Sets the number of CPU cores for an instance."
}

variable "iam_instance_profile" {
  type        = string
  default     = ""
  description = "The IAM Instance Profile to launch the instance with. Specified as the name of the Instance Profile."
}

variable "cpu_credits" {
  type        = string
  default     = "standard"
  description = "The credit option for CPU usage. Can be `standard` or `unlimited`. T3 instances are launched as unlimited by default. T2 instances are launched as standard by default."
}

variable "instance_tags" {
  type        = map(any)
  default     = {}
  description = "Instance tags."
}
variable "spot_instance_tags" {
  type        = map(any)
  default     = {}
  description = "Instance tags."
}

variable "dns_zone_id" {
  type        = string
  default     = "Z1XJD7SSBKXLC1"
  description = "The Zone ID of Route53."
  sensitive   = true
}

variable "dns_enabled" {
  type        = bool
  default     = false
  description = "Flag to control the dns_enable."
}

variable "hostname" {
  type        = string
  default     = "ec2"
  description = "DNS records to create."
  sensitive   = true
}

variable "type" {
  type        = string
  default     = "CNAME"
  description = "Type of DNS records to create."
}

variable "ttl" {
  type        = string
  default     = "300"
  description = "The TTL of the record to add to the DNS zone to complete certificate validation."
}

variable "metadata_http_tokens_required" {
  type        = string
  default     = "optional"
  description = "Whether or not the metadata service requires session tokens, also referred to as Instance Metadata Service Version 2 (IMDSv2). Valid values include optional or required. Defaults to optional."
}

variable "metadata_http_endpoint_enabled" {
  type        = string
  default     = "enabled"
  description = "Whether the metadata service is available. Valid values include enabled or disabled. Defaults to enabled."
}

variable "instance_metadata_tags_enabled" {
  type        = string
  default     = "enabled"
  description = "Whether the metadata service is available. Valid values include enabled or disabled. Defaults to enabled."
}

variable "metadata_http_put_response_hop_limit" {
  type        = number
  default     = 2
  description = "The desired HTTP PUT response hop limit (between 1 and 64) for instance metadata requests."
}

variable "hibernation" {
  type        = bool
  default     = false
  description = "hibernate an instance, Amazon EC2 signals the operating system to perform hibernation."
}

variable "kms_key_id" {
  type        = string
  default     = ""
  description = "The ARN of the key that you wish to use if encrypting at rest. If not supplied, uses service managed encryption. Can be specified only if at_rest_encryption_enabled = true."
}

### key-pair #####

variable "enable_key_pair" {
  type        = bool
  default     = true
  description = "A boolean flag to enable/disable key pair."
}

variable "public_key" {
  type        = string
  default     = ""
  description = "Name  (e.g. `ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQD3F6tyPEFEzV0LX3X8BsXdMsQ`)."
  sensitive   = true
}

variable "key_path" {
  type        = string
  default     = ""
  description = "Name  (e.g. `~/.ssh/id_rsa.pub`)."
}

###### spot
variable "spot_instance_enabled" {
  type        = bool
  default     = true
  description = "Flag to control the instance creation."
}

variable "spot_instance_count" {
  type        = number
  default     = 0
  description = "Number of instances to launch."
}

variable "spot_price" {
  type        = string
  default     = null
  description = "The maximum price to request on the spot market. Defaults to on-demand price"
}

variable "spot_wait_for_fulfillment" {
  type        = bool
  default     = false
  description = "If set, Terraform will wait for the Spot Request to be fulfilled, and will throw an error if the timeout of 10m is reached"
}

variable "spot_type" {
  type        = string
  default     = null
  description = "If set to one-time, after the instance is terminated, the spot request will be closed. Default `persistent`"
}

variable "spot_launch_group" {
  type        = string
  default     = null
  description = "A launch group is a group of spot instances that launch together and terminate together. If left empty instances are launched and terminated individually"
}

variable "spot_block_duration_minutes" {
  type        = number
  default     = null
  description = "The required duration for the Spot instances, in minutes. This value must be a multiple of 60 (60, 120, 180, 240, 300, or 360)"
}

variable "spot_instance_interruption_behavior" {
  type        = string
  default     = null
  description = "Indicates Spot instance behavior when it is interrupted. Valid values are `terminate`, `stop`, or `hibernate`"
}

variable "spot_valid_until" {
  type        = string
  default     = null
  description = "The end date and time of the request, in UTC RFC3339 format(for example, YYYY-MM-DDTHH:MM:SSZ)"
}

variable "spot_valid_from" {
  type        = string
  default     = null
  description = "The start date and time of the request, in UTC RFC3339 format(for example, YYYY-MM-DDTHH:MM:SSZ)"
}

variable "ebs_block_device" {
  description = "Additional EBS block devices to attach to the instance"
  type        = list(any)
  default     = []
}

variable "key_name" {
  default     = ""
  description = "The name for the key pair. Conflicts with `key_name_prefix`"
}
