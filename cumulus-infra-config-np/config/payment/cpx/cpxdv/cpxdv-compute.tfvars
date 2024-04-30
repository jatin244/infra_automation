#######################################################locals###########################################################
transit_gateway_id           = "tgw-0ae34d2891f6f7fa6"
transit_gateway_spoke_rtb_id = "tgw-rtb-046ed68471dbcda81"
transit_gateway_spoke_int_id = "tgw-rtb-04525ebd8e7473a31"
egress_vpc_public_rtb_id     = "rtb-00c2387634e6cd021"
ingress_vpc_cidr             = "172.25.128.0/20"
ingress_vpc_public_rtb_id    = "rtb-0e56bda3cf62ea1ca"
ingress_vpc_id               = "vpc-06aa86de510d0509c"
ops_vpc_cidr                 = "172.25.80.0/20"
ops_vpc_id                   = "vpc-0d94d18ef5e46a956"
dns_vpc_id                   = "vpc-0d961bd68b1276be6"
hosted_zone_name             = "np.prth.local"
hosted_zone_id               = "Z0564577CIT7N7I4E8PL"

####################################################data-vpc############################################################
data_vpc_cidr = "10.44.0.0/20"

####################################################application-vpc#####################################################


#######################################################security-group#########################################################
redis_sg_cidr_blocks            = ["10.254.0.0/16", "172.25.80.0/20"]
secure_redis_sg_cidr_blocks     = ["10.254.0.0/16", "172.25.80.0/20"]
mysql_sg_cidr_blocks            = ["10.254.0.0/16", "172.25.80.0/20", "10.238.0.0/16", "172.26.0.0/20", "172.25.83.35/32", "10.238.108.8/32"]
msk_sg_cidr_blocks              = ["10.254.0.0/16", "172.25.80.0/20", "10.238.0.0/16"]
ssh_sg_cidr_blocks              = ["10.254.0.0/16", "172.25.80.0/20"]
etcd_ec2_sg_cidr_blocks         = ["10.254.0.0/16", "172.25.80.0/20"]
es_ec2_sg_cidr_blocks           = ["10.254.0.0/16", "172.25.80.0/20"]
es_nlb_sg_cidr_blocks           = ["10.254.0.0/16", "172.25.80.0/20"]

#######################################################secrets_manager##################################################
recovery_window_in_days = 0

##############################redis-cluster#############################################################################
redis_cluster_enabled = "true"
redis_engine_version = "6.2"
redis_node_type      = "cache.r6g.large"

##############################secure-redis-cluster#############################################################################
secure_redis_cluster_enabled = "false"
secure_redis_engine_version = "6.2"
secure_redis_node_type      = "cache.t3.small"

#######################################################mysql############################################################
mysql_enabled = "true"
mysql_engine_version    = "8.0.28"
mysql_instance_class    = "db.r6g.2xlarge"
mysql_allocated_storage = 1000

#######################################################mysql-read-replica############################################################
enabled_replica = "false"
replica_instance_class = "db.t3.small"
############################DB parameter group######################
mysql_family = "mysql8.0"

mysql_parameters = [
    {
      name  = "long_query_time"
      value = "2"
    },
    {
      name  = "sort_buffer_size"
      value = "524288"
    }
  ]

##############################DB option group#######################
mysql_major_engine_version = "8.0"

##################################################################EKS###################################################
eks_allowed_cidr_blocks_cluster = ["172.25.80.0/20", "10.238.21.43/32", "10.254.0.0/16"]


node_groups = {
  mgmt = {
        node_group_name           = "mgmt-tools"
        node_group_instance_type = "c7i.large"
        kubernetes_labels         = {
                   Group = "mgmt-tools"
                }
        taints                    = []
        node_group_capacity_type  = "ON_DEMAND"
        ami_type                  = "AL2_x86_64"
        ami_release_version       = "1.27.5-20231002"
        node_group_desired_size   = 1
        node_group_max_size       = 2
        node_group_min_size       = 1
        node_group_volume_size    = "100"
        node_group_volume_type    = "gp2"
        subnet_component_tag      = "eks-mgmt"
      },
  product-shared = {
        node_group_name           = "product-shared"
        node_group_instance_type = "c7i.2xlarge"
        kubernetes_labels         = {
                   Group = "product-shared"
                }
        taints                    = []
        node_group_capacity_type  = "ON_DEMAND"
        ami_type                  = "AL2_x86_64"
        ami_release_version       = "1.27.5-20231002"
        node_group_desired_size   = 3
        node_group_max_size       = 4
        node_group_min_size       = 2
        node_group_volume_size    = "100"
        node_group_volume_type    = "gp2"
        subnet_component_tag      = "eks-product-shared"  
    }
  product-open-net = {
        node_group_name           = "product-open-net"
        node_group_instance_type = "c7i.2xlarge"
        kubernetes_labels         = {
                   Group = "product-open-net"
                }
        taints                    = []
        node_group_capacity_type  = "ON_DEMAND"
        ami_type                  = "AL2_x86_64"
        ami_release_version       = "1.27.5-20231002"
        node_group_desired_size   = 2
        node_group_max_size       = 4
        node_group_min_size       = 1
        node_group_volume_size    = "100"
        node_group_volume_type    = "gp2"
        subnet_component_tag      = "eks-open-net"  
    }
    ds = {
        node_group_name           = "ds"
        node_group_instance_type = "c7i.xlarge"
        kubernetes_labels         = {
                   Group = "ds"
                }
        taints                    = []
        node_group_capacity_type  = "ON_DEMAND"
        ami_type                  = "AL2_x86_64"
        ami_release_version       = "1.27.5-20231002"
        node_group_desired_size   = 2
        node_group_max_size       = 3
        node_group_min_size       = 1
        node_group_volume_size    = "100"
        node_group_volume_type    = "gp2"
        subnet_component_tag      = "eks-ds"  
    }
}
#######################################################kafka############################################################
msk_cluster_enabled = "false"
kafka_version             = "2.6.2"
broker_node_instance_type = "kafka.t3.small"
kafka_broker_number = 2
configuration_server_properties = {
  "auto.create.topics.enable" = true
  "delete.topic.enable"       = true
}
schema_registries = {
  vortex = {
    name        = "cscale"
    description = "Schema registry for cscale"
  }
}
schemas = {
  vortex = {
    schema_registry_name = "vortex"
    schema_name          = "cscale"
    description          = "Schema that contains all the cscale data"
    compatibility        = "FORWARD"
    schema_definition    = "{\"type\": \"record\", \"name\": \"r1\", \"fields\": [ {\"name\": \"f1\", \"type\": \"int\"}, {\"name\": \"f2\", \"type\": \"string\"} ]}"
  }
}
auto_scaling_storage_enabled = "false"
broker_node_ebs_volume_size = 50
####################etcd-ec2###################################################################
etcd_ec2_enabled = "false"
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
etcd_ec2_ebs_block_device = [
  {
    device_name = "/dev/xvdb"
    volume_type = "gp3"
    volume_size = 5
    throughput  = 200
    encrypted   = true
    delete_on_termination = true
  },
  {
    device_name = "/dev/xvdc"
    volume_type = "gp3"
    volume_size = 50
    throughput  = 200
    encrypted   = true
    delete_on_termination = true
  }
]

####################es-ec2###################################################################
es_ec2_enabled ="true"
es_ec2_instance_count = 3
es_ec2_ami            = "ami-04f178e9f970f279e"
es_ec2_instance_type  = "r6in.xlarge"
es_ec2_root_block_device = [
  {
    volume_type           = "gp3"
    volume_size           = 100
    delete_on_termination = true
    encrypted   = true
  }
]
es_ec2_ebs_block_device = [
  {
    device_name = "/dev/sdb"
    volume_type = "gp3"
    volume_size = 100
    iops = 4000
    throughput  = 1000
    encrypted   = true
    delete_on_termination = true
  }
]

instance_tags = { "snapshot" = true }
key_name = "fnx_dev_commonkey"

###############################es-nlb#######################################################################
es_nlb_enabled = "true"
es_nlb_http_tcp_listeners = [
  { 
    port               = 443
    protocol           = "TCP"
    target_group_index = 0
  },
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
         path   = "/login"
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
