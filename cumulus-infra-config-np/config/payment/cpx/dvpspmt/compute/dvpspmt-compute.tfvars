#######################################################security-group#########################################################
redis_sg_cidr_blocks            = ["10.254.0.0/16", "10.101.16.0/20"]
secure_redis_sg_cidr_blocks     = ["10.254.0.0/16", "10.101.16.0/20"]
mysql_sg_cidr_blocks            = ["10.254.0.0/16", "10.101.16.0/20"]
msk_sg_cidr_blocks              = ["10.254.0.0/16", "10.101.16.0/20"]
ssh_sg_cidr_blocks              = ["10.254.0.0/16", "10.101.16.0/20", "10.105.224.0/20"]
etcd_ec2_sg_cidr_blocks         = ["10.254.0.0/16", "10.101.16.0/20"]
es_ec2_sg_cidr_blocks           = ["10.254.0.0/16", "10.101.16.0/20"]
es_nlb_sg_cidr_blocks           = ["10.254.0.0/16", "10.101.16.0/20"]

#######################################################secrets_manager##################################################
recovery_window_in_days = 0

##############################redis-cluster#############################################################################
redis_cluster_enabled = "true"
redis_engine_version = "6.2"
redis_node_type      = "cache.t3.small"

##############################secure-redis-cluster#############################################################################
secure_redis_cluster_enabled = "true"
secure_redis_engine_version = "6.2"
secure_redis_node_type      = "cache.t3.small"

#######################################################mysql############################################################
mysql_enabled = "true"
mysql_engine_version    = "8.0.28"
mysql_instance_class    = "db.t3.small"
mysql_allocated_storage = 50

#######################################################mysql-read-replica############################################################
enabled_replica = "false"
replica_instance_class = "db.t3.small"
############################DB parameter group######################
mysql_parameter_group_name = "mysqlappdb-80-ci"

##############################DB option group#######################
mysql_major_engine_version = "8.0"

##################################################################EKS###################################################
#AWS Optimized AMI Github change log tracker- https://github.com/awslabs/amazon-eks-ami/blob/master/CHANGELOG.md
eks_enabled = true
kubernetes_version = 1.28
eks_allowed_cidr_blocks_cluster = ["10.254.0.0/16", "10.238.21.43/32", "10.101.16.0/20", "10.105.224.0/20"]

node_group_enabled = true
node_groups = {
  mgmt = {
        node_group_name           = "mgmt-tools"
        node_group_instance_type = "r6i.large"
        kubernetes_labels         = {
                   Group = "mgmt-tools"
                }
        taints                    = []
        node_group_capacity_type  = "ON_DEMAND"
        ami_type                  = "AL2_x86_64"
        ami_release_version       = "1.28.5-20240213"
        node_group_desired_size   = 1
        node_group_max_size       = 2
        node_group_min_size       = 1
        node_group_volume_size    = "100"
        node_group_volume_type    = "gp3"
        subnet_component_tag      = "eks-mgmt"
      },
  product-shared = {
        node_group_name           = "product-shared"
        node_group_instance_type = "c7i.xlarge"
        kubernetes_labels         = {
                   Group = "product-shared"
                }
        taints                    = []
        node_group_capacity_type  = "ON_DEMAND"
        ami_type                  = "AL2_x86_64"
        ami_release_version       = "1.28.5-20240213"
        node_group_desired_size   = 1
        node_group_max_size       = 2
        node_group_min_size       = 1
        node_group_volume_size    = "100"
        node_group_volume_type    = "gp2"
        subnet_component_tag      = "eks-product-shared"  
    }
    ds = {
        node_group_name           = "ds"
        node_group_instance_type = "r6i.large"
        kubernetes_labels         = {
                   Group = "ds"
                }
        taints                    = []
        node_group_capacity_type  = "ON_DEMAND"
        ami_type                  = "AL2_x86_64"
        ami_release_version       = "1.28.5-20240213"
        node_group_desired_size   = 1
        node_group_max_size       = 2
        node_group_min_size       = 1
        node_group_volume_size    = "100"
        node_group_volume_type    = "gp2"
        subnet_component_tag      = "eks-ds"  
    }
}

#fargate_enabled = true
#fargate_profiles = {
#  profile-default = {
#    addon_name = "default"
#    namespace  = "default"
#    subnet_component_tag = "eks-product-shared"
#  },
#  profile-tester = {
#    addon_name = "tester"
#    namespace = "tester"
#    subnet_component_tag      = "eks-ds"
#  }  
#}
#######################################################kafka############################################################
msk_cluster_enabled = "true"
kafka_version             = "2.6.2"
broker_node_instance_type = "kafka.t3.small"
kafka_broker_number = 2
configuration_server_properties = {
  "auto.create.topics.enable" = true
  "delete.topic.enable"       = true
}
auto_scaling_storage_enabled = "false"
broker_node_ebs_volume_size = 50

###Glue for MSK
schema_registries = {
  dvpspmt = {
    name        = "dvpspmt"
    description = "Schema registry for dvpspmt"
  }
}
schemas = {
  dvpspmt = {
    schema_registry_name = "dvpspmt"
    schema_name          = "pmt"
    description          = "Schema that contains all the dvpspmt data"
    compatibility        = "FORWARD"
    schema_definition    = "{\"type\": \"record\", \"name\": \"r1\", \"fields\": [ {\"name\": \"f1\", \"type\": \"int\"}, {\"name\": \"f2\", \"type\": \"string\"} ]}"
  }
}

####################etcd-ec2###################################################################
etcd_ec2_enabled = true
etcd_ec2_instance_count = 3
etcd_ec2_ami            = "ami-04f178e9f970f279e"
etcd_ec2_instance_type  = "t3.small"
etcd_ec2_root_block_device = [
  {
    volume_type           = "gp3"
    volume_size           = 30
    delete_on_termination = true
    encrypted   = true
  }
]
#xvdb will be auto mounted on /var/lib/etcd via userdata
etcd_ec2_ebs_block_device = [
  {
    device_name = "/dev/xvdb"
    volume_type = "gp3"
    volume_size = 5
    throughput  = 200
    encrypted   = true
    delete_on_termination = true
  }
]

####################es-ec2###################################################################
es_ec2_enabled ="true"
es_ec2_instance_count = 2
es_ec2_ami            = "ami-04f178e9f970f279e"
es_ec2_instance_type  = "r6i.large"
es_ec2_root_block_device = [
  {
    volume_type           = "gp3"
    volume_size           = 30
    delete_on_termination = true
    encrypted   = true
  }
]
es_ec2_ebs_block_device = [
  {
    device_name = "/dev/sdb"
    volume_type = "gp3"
    volume_size = 50
    iops = 5000
    throughput  = 200
    encrypted   = true
    delete_on_termination = true
  }
]

instance_tags = { "snapshot" = true }
key_name = "fnx_dev_commonkey"

###############################es-nlb#######################################################################
es_nlb_enabled = "true"
es_nlb_https_listeners = [
       {  
         port = 443
         protocol = "TLS"
         target_group_index = 0
         certificate_arn = "arn:aws:acm:us-east-1:366674262526:certificate/b915fead-20be-4ff0-b2d2-9a6434b0fac0"
       }
]
es_nlb_http_tcp_listeners = [
  {
    port               = 9200
    protocol           = "TCP"
    target_group_index = 1
  },
]
es_target_groups = [
  {
    backend_protocol = "TCP"
    backend_port     = 443
    target_type      = "instance"
    health_check     = {
         path	= "/login"
         matcher = "200-399"
         protocol = "HTTPS"
     }
  },
  {
    backend_protocol = "TCP"
    backend_port     = 9200
    target_type      = "instance"
  },
]
