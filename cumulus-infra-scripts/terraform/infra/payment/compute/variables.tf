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

#####################################local##########################

variable "creds_profile" {
  default = "default"
}
variable "ops_vpc_id" {
}
variable "dns_vpc_id" {
}
variable "common_tags" {
  default = {}
}
variable "transit_gateway_id" {
}
variable "transit_gateway_spoke_rtb_id" {
}
variable "transit_gateway_spoke_int_id" {
}
variable "egress_vpc_public_rtb_id" {
}
variable "ingress_vpc_public_rtb_id" {
}
variable "ingress_vpc_id" {
}
variable "ingress_vpc_cidr" {
}
variable "ops_vpc_cidr" {
}
variable "hosted_zone_name" {
}
variable "hosted_zone_id" {
}
#########################################################

variable "region" {
  default = "us-east-1"
}
variable "environment" {
}
variable "managedby" {
  default = "IDC Cloud Services"
}
variable "label_order" {
  default = ["environment", "name"]
}
variable "product" {
  default = "vtx"
}
variable "data_vpc_id" {
  default = ""
}
variable "application_vpc_id" {
  default = ""
}
variable "data_vpc_cidr" {
}
variable "application_vpc_cidr" {
}
variable "data_vpc_enabled" {
  default = true
}
variable "application_vpc_enabled" {
  default = true
}


######################################mysql_sg###################################

variable "security_enabled" {
  default = true
}
variable "mysql_sg_name" {
  default = "mysql-sg"
}
variable "mysql_sg_type" {
  default = "ingress"
}
variable "mysql_sg_source_security_group_name" {
  default = null
}
variable "mysql_sg_source_security_group_id" {
  default = null
}
variable "mysql_sg_from_port" {
  default = 3306
}
variable "mysql_sg_to_port" {
  default = 3306
}
variable "mysql_sg_protocol" {
  default = "tcp"
}
variable "mysql_sg_prefix_list_ids" {
  default = null
}
variable "mysql_sg_self" {
  default = null
}

################################ssh_sg##############################

variable "egress_allow_cidr_blocks" {
  default = ["0.0.0.0/0"]
}
variable "egress_type" {
  default = "egress"
}
variable "ssh_sg_name" {
  default = "ssh-sg"
}
variable "ssh_sg_type" {
  default = "ingress"
}
variable "ssh_sg_source_security_group_name" {
  default = null
}
variable "ssh_sg_source_security_group_id" {
  default = null
}
variable "ssh_sg_from_port" {
  default = 22
}
variable "ssh_sg_to_port" {
  default = 22
}
variable "ssh_sg_protocol" {
  default = "tcp"
}
variable "ssh_sg_prefix_list_ids" {
  default = null
}
variable "ssh_sg_self" {
  default = null
}
variable "ssh_sg_cidr_blocks" {
  default = []
}

################################msk_sg##############################

variable "msk_sg_name" {
  default = "msk-sg"
}
variable "msk_sg_type" {
  default = "ingress"
}
variable "msk_sg_source_security_group_name" {
  default = null
}
variable "msk_sg_source_security_group_id" {
  default = null
}
variable "msk_sg_from_port" {
  default = 9094
}
variable "msk_sg_to_port" {
  default = 9094
}
variable "msk_sg_protocol" {
  default = "tcp"
}
variable "msk_sg_prefix_list_ids" {
  default = null
}
variable "msk_sg_self" {
  default = null
}
variable "msk_sg_cidr_blocks" {
  default = []
}

######################################redis_sg###################################

variable "redis_sg_name" {
  default = "redis-sg"
}
variable "redis_sg_type" {
  default = "ingress"
}
variable "redis_sg_source_security_group_name" {
  default = null
}
variable "redis_sg_source_security_group_id" {
  default = null
}
variable "redis_sg_from_port" {
  default = 6379
}
variable "redis_sg_to_port" {
  default = 6379
}
variable "redis_sg_protocol" {
  default = "tcp"
}
variable "redis_sg_prefix_list_ids" {
  default = null
}
variable "redis_sg_self" {
  default = null
}
variable "redis_sg_cidr_blocks" {
  default = []
}

######################################secure_redis_sg###################################

variable "secure_redis_sg_name" {
  default = "secure-redis-sg"
}
variable "secure_redis_sg_type" {
  default = "ingress"
}
variable "secure_redis_sg_source_security_group_name" {
  default = null
}
variable "secure_redis_sg_source_security_group_id" {
  default = null
}
variable "secure_redis_sg_from_port" {
  default = 6379
}
variable "secure_redis_sg_to_port" {
  default = 6379
}
variable "secure_redis_sg_protocol" {
  default = "tcp"
}
variable "secure_redis_sg_prefix_list_ids" {
  default = null
}
variable "secure_redis_sg_self" {
  default = null
}
variable "secure_redis_sg_cidr_blocks" {
  default = []
}

################################etcd-ec2_sg##############################
variable "etcd_ec2_sg_name" {
  default = "etcd-ec2-sg"
}
variable "etcd_ec2_sg_type" {
  default = "ingress"
}
variable "etcd_ec2_sg_source_security_group_name" {
  default = null
}
variable "etcd_ec2_sg_source_security_group_id" {
  default = null
}
variable "etcd_ec2_sg_from_port" {
  default = 80
}
variable "etcd_ec2_sg_to_port" {
  default = 80
}
variable "etcd_ec2_sg_protocol" {
  default = "tcp"
}
variable "etcd_ec2_sg_prefix_list_ids" {
  default = null
}
variable "etcd_ec2_sg_self" {
  default = null
}
variable "etcd_ec2_sg_cidr_blocks" {
  default = []
}

################################es-ec2_sg##############################
variable "es_ec2_sg_name" {
  default = "es-ec2-sg"
}
variable "es_ec2_sg_type" {
  default = "ingress"
}
variable "es_ec2_sg_source_security_group_name" {
  default = null
}
variable "es_ec2_sg_source_security_group_id" {
  default = null
}
variable "es_ec2_sg_from_port" {
  default = 80
}
variable "es_ec2_sg_to_port" {
  default = 80
}
variable "es_ec2_sg_protocol" {
  default = "tcp"
}
variable "es_ec2_sg_prefix_list_ids" {
  default = null
}
variable "es_ec2_sg_self" {
  default = null
}
variable "es_ec2_sg_cidr_blocks" {
  default = []
}

################################es-nlb_sg##############################
variable "es_nlb_sg_name" {
  default = "es-nlb-sg"
}
variable "es_nlb_sg_type" {
  default = "ingress"
}
variable "es_nlb_sg_source_security_group_name" {
  default = null
}
variable "es_nlb_sg_source_security_group_id" {
  default = null
}
variable "es_nlb_sg_from_port" {
  default = 80
}
variable "es_nlb_sg_to_port" {
  default = 80
}
variable "es_nlb_sg_protocol" {
  default = "tcp"
}
variable "es_nlb_sg_prefix_list_ids" {
  default = null
}
variable "es_nlb_sg_self" {
  default = null
}
variable "es_nlb_sg_cidr_blocks" {
  default = []
}

#################################redis###################

variable "redis_cluster_enabled" {
  default = true
}
variable "parameter_group_name" {
  default = "default.redis6.x"
}
variable "redis_node_type" {
  default = "cache.r6g.large"
}
variable "redis_availability_zones" {
  default = ["us-east-1a", "us-east-1b"]
}
variable "redis_port" {
  default = "6379"
}
variable "redis_engine" {
  default = "redis"
}
variable "redis_engine_version" {
}
variable "replicas_per_node_group" {
  default     = ""
  description = "Replicas per Shard."
}
variable "num_node_groups" {
  default     = ""
  description = "Number of Shards (nodes)."
}

#################################secure-redis###################

variable "secure_redis_cluster_enabled" {
  default = false
}
variable "secure_parameter_group_name" {
  default = "default.redis6.x"
}
variable "secure_redis_node_type" {
  default = "cache.r6g.large"
}
variable "secure_redis_availability_zones" {
  default = ["us-east-1a", "us-east-1b"]
}
variable "secure_redis_port" {
  default = "6379"
}
variable "secure_redis_engine" {
  default = "redis"
}
variable "secure_redis_engine_version" {
}
variable "secure_replicas_per_node_group" {
  default     = ""
  description = "Replicas per Shard."
}
variable "secure_num_node_groups" {
  default     = ""
  description = "Number of Shards (nodes)."
}

###############################kms_rds############################
variable "kms_description" {
  default = "KMS Key for RDS encryption for stack"
}
variable "key_usage" {
  default = "ENCRYPT_DECRYPT"
}
variable "customer_master_key_spec" {
  default = "SYMMETRIC_DEFAULT"
}
variable "enable_key_rotation" {
  default = "true"
}
variable "multi_region" {
  default = "true"
}

###############################kms_kafka############################

variable "kafka_kms_description" {
  default = "KMS Key for kafka encryption for stack"
}
variable "kafka_key_usage" {
  default = "ENCRYPT_DECRYPT"
}
variable "kafka_customer_master_key_spec" {
  default = "SYMMETRIC_DEFAULT"
}
variable "kafka_enable_key_rotation" {
  default = "true"
}
variable "kafka_multi_region" {
  default = "true"
}

###############################kms_redis############################

variable "redis_kms_description" {
  default = "KMS Key for Redis encryption for stack"
}
variable "redis_key_usage" {
  default = "ENCRYPT_DECRYPT"
}
variable "redis_customer_master_key_spec" {
  default = "SYMMETRIC_DEFAULT"
}
variable "redis_enable_key_rotation" {
  default = "true"
}
variable "kms_redis_multi_region" {
  default = "true"
}

###############################route53_record################################

variable "route53_record_type" {
  default = "CNAME"
}
variable "route53_record_ttl" {
  default = "3600"
}
variable "ec2_route53_record_type" {
  default = "A"
}

################################secrets_manager##########################

variable "secrets_enabled" {
  default = true
}
variable "recovery_window_in_days" {
}

###################################mysql############################

variable "mysql_enabled" {
  default = true
}
variable "enabled_read_replica" {
  default = true
}
variable "mysql_parameter_group_name" {
  default = null
}
variable "mysql_replica_instance_class" {
  default = "db.t3.small"
}
variable "mysql_engine" {
  default = "mysql"
}
variable "mysql_engine_version" {
}
variable "mysql_instance_class" {
}
variable "mysql_allocated_storage" {
}
variable "mysql_database_name" {
  default = "vtx"
}
variable "mysql_username" {
  default = "root"
}
variable "mysql_port" {
  default = "3306"
}
variable "mysql_maintenance_window" {
  default = "Mon:00:00-Mon:03:00"
}
variable "mysql_backup_window" {
  default = "03:00-06:00"
}
variable "mysql_multi_az" {
  default = false
}
variable "mysql_backup_retention_period" {
  default = 0
}
variable "mysql_enabled_cloudwatch_logs_exports" {
  default = ["audit", "general"]
}
variable "mysql_publicly_accessible" {
  default = false
}
variable "mysql_family" {
  default = "mysql8.0"
}
variable "mysql_major_engine_version" {
}
variable "mysql_deletion_protection" {
  default = false
}
variable "mysql_parameters" {
default = []
 # default = [
 #   {
 #     name  = "character_set_client"
 #     value = "utf8"
 #   },
 #   {
 #     name  = "character_set_server"
 #     value = "utf8"
 #   }
 # ]
}
variable "mysql_option_group_enabled" {
  type    = bool
  default = false
}
variable "mysql_option_group_name" {
  type    = string
  default = ""
}
variable "options" {
  default = [
    {
      option_name = "MARIADB_AUDIT_PLUGIN"

      option_settings = [
        {
          name  = "SERVER_AUDIT_EVENTS"
          value = "CONNECT"
        },
        {
          name  = "SERVER_AUDIT_FILE_ROTATIONS"
          value = "37"
        },
      ]
    },
  ]
}
variable "mysql_sg_cidr_blocks" {
  default = []
}

##########################mysql-read-replica#####################
variable "replica_instance_class" {
  description = "The instance type of the RDS instance"
  type        = string
  default     = ""
}

variable "enabled_replica" {
  type    = bool
  default = false
}
##########################eks####################################

variable "node_group_enabled" {
  default = true
}
variable "node_groups" {
}
variable "eks_enabled" {
  default = true
}
variable "kubernetes_version" {
  default = "1.27"
}
variable "endpoint_private_access" {
  default = true
}
variable "endpoint_public_access" {
  default = false
}
variable "enabled_cluster_log_types" {
  default = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}
variable "allowed_cidr_blocks" {
  default = ["0.0.0.0/0"]
}
variable "fargate_enabled" {
  default = false
}
variable "fargate_profiles" {
  default = {}
}
variable "eks_allowed_cidr_blocks_cluster" {
}
variable "node_group_name" {
  default = "critical-node-group"
}
variable "apply_config_map_aws_auth" {
  default = "false"
}
variable "kubernetes_config_map_ignore_role_changes" {
  default = "true"
}
variable "map_additional_iam_users" {
  default = []
}
variable "map_additional_iam_roles" {
  default = []
}


###############################kafka###############################

variable "kafka_version" {
}
variable "msk_cluster_enabled" {
  default = true
}
variable "kafka_broker_number" {
  default = 2
}
variable "broker_node_ebs_volume_size" {
  default = 20
}
variable "broker_node_instance_type" {
}
variable "scaling_max_capacity" {
  default = 512
}
variable "scaling_target_value" {
  default = 80
}
variable "auto_scaling_storage_enabled" {
  default = true
}
variable "encryption_in_transit_client_broker" {
  default = "TLS_PLAINTEXT"
}
variable "encryption_in_transit_in_cluster" {
  default = true
}
variable "transit_encryption_enabled" {
  default = false
}
variable "auth_token" {
  default = null
}
variable "configuration_server_properties" {
}
variable "jmx_exporter_enabled" {
  default = true
}
variable "node_exporter_enabled" {
  default = true
}
variable "cloudwatch_logs_enabled" {
  default = true
}
variable "s3_logs_enabled" {
  default = true
}
variable "s3_logs_prefix" {
  default = "logs/msk"
}
variable "client_authentication_sasl_scram" {
  default = false
}
variable "create_scram_secret_association" {
  default = false
}
variable "schema_registries" {
}
variable "schemas" {
}

##################################################policy###############################################

variable "policy_enabled" {
  default = true
}

variable "db_snapshot_identifier" {
  default = ""
}

variable "skip_final_snapshot" {
  default = true
}

variable "s3_bucket_enabled" {
  default = true
}
variable "s3_force_destroy" {
  default = true
}
variable "s3_attributes" {
  default = ["private"]
}
variable "s3_versioning" {
  default = true
}
variable "s3_acl" {
  default = "private"
}
variable "s3_name" {
  default = "msk-logs-bucket"
}

###############################ec2_kms############################

variable "ec2_kms_description" {
  default = "KMS Key for ec2 encryption for stack"
}
variable "ec2_key_usage" {
  default = "ENCRYPT_DECRYPT"
}
variable "ec2_customer_master_key_spec" {
  default = "SYMMETRIC_DEFAULT"
}
variable "ec2_enable_key_rotation" {
  default = "true"
}
variable "kms_ec2_multi_region" {
  default = "true"
}

###############################elasticsearch-ec2#######################
variable "es_ec2_enabled" {
  default = true
}
variable "es_ec2_instance_count" {}
variable "es_ec2_ami" {}
variable "es_ec2_instance_type" {}
variable "es_ec2_root_block_device" {}
variable "es_ec2_ebs_block_device" {}

###############################etcd-ec2#######################
variable "etcd_ec2_enabled" {
  default = true
}
variable "etcd_ec2_instance_count" {}
variable "etcd_ec2_ami" {}
variable "etcd_ec2_instance_type" {}
variable "etcd_ec2_root_block_device" {}
variable "etcd_ec2_ebs_block_device" {}



###############################common-ec2#######################

variable "instance_tags" {}

variable "public_key" {
  default = ""
}
variable "key_name" {
  default = ""
}



###############################es-nlb#######################
variable "es_nlb_enabled" {
  default = true
}
variable "es_nlb_http_tcp_listeners" {
  default = []
}
variable "es_nlb_https_listeners" {
  default = []
}
variable "es_target_groups" {
  default = []
}
variable "es_nlb_enable_deletion_protection" {
  default = false
}
variable "es_nlb_with_target_group" {
  default = true
} 
