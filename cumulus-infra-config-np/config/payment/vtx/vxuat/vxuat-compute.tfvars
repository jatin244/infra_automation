#######################################################security-group#########################################################
eks_sg_cidr_blocks       = ["10.238.224.0/24", "10.238.72.0/24", "172.25.80.0/20", "10.155.1.0/24", "10.155.4.0/24", "10.254.0.0/16", "172.71.80.0/20", "10.238.21.43/32"]
redis_sg_cidr_blocks     = ["10.238.224.0/24", "10.238.72.0/24", "172.25.80.0/20", "10.155.1.0/24", "10.155.4.0/24", "10.254.0.0/16", "172.71.80.0/20"]
mysql_sg_cidr_blocks     = ["10.238.224.0/24", "10.238.72.0/24", "172.25.80.0/20", "10.155.1.0/24", "10.155.4.0/24", "10.254.0.0/16", "172.71.80.0/20", "172.26.0.0/20", "10.238.76.0/24"]
msk_sg_cidr_blocks       = ["10.238.224.0/24", "10.238.72.0/24", "172.25.80.0/20", "10.155.1.0/24", "10.155.4.0/24", "10.254.0.0/16", "172.71.80.0/20"]
ssh_sg_cidr_blocks       = ["10.238.224.0/24", "10.238.72.0/24", "172.25.80.0/20", "10.155.1.0/24", "10.155.4.0/24", "10.254.0.0/16", "172.71.80.0/20"]
etcd_ec2_sg_cidr_blocks  = ["10.238.224.0/24", "10.238.72.0/24", "172.25.80.0/20", "10.155.1.0/24", "10.155.4.0/24", "10.254.0.0/16", "172.71.80.0/20"]
es_ec2_sg_cidr_blocks    = ["10.238.224.0/24", "10.238.72.0/24", "172.25.80.0/20", "10.155.1.0/24", "10.155.4.0/24", "10.254.0.0/16", "172.71.80.0/20"]
es_nlb_sg_cidr_blocks    = ["10.238.224.0/24", "10.238.72.0/24", "172.25.80.0/20", "10.155.1.0/24", "10.155.4.0/24", "10.254.0.0/16", "172.71.80.0/20"]
secure_redis_sg_cidr_blocks     = ["10.238.224.0/24", "10.238.72.0/24", "172.25.80.0/20", "10.155.1.0/24", "10.155.4.0/24", "10.254.0.0/16", "172.71.80.0/20"]

#AS Team VDI- "10.238.224.0/24"
#Admins VDI - "10.238.72.0/24"
#CS Non-Prod Ops VPC - "172.25.80.0/20"
#CS Admin AWS Workspace- "10.155.1.0/24", "10.155.4.0/24"
#VPN - "10.254.0.0/16"
#AS NonProd Ops VPC - "172.71.80.0/20"
#Octopus - "10.238.21.43/32"
#DB Ops - "172.26.0.0/20"
#DB Team VDI -  "10.238.76.0/24"


#######################################################secrets_manager##################################################
recovery_window_in_days = 0

##############################redis-cluster#############################################################################
redis_cluster_enabled = "true"
redis_engine_version = "6.2"
redis_node_type      = "cache.r6g.xlarge"

##############################secure-redis-cluster#############################################################################
secure_redis_cluster_enabled = "false"
secure_redis_engine_version = "6.2"
secure_redis_node_type      = "cache.r6g.xlarge"

#######################################################mysql############################################################
mysql_enabled = "true"
mysql_engine_version    = "8.0.34"
mysql_instance_class    = "db.r6g.2xlarge"
mysql_allocated_storage = 500

#######################################################mysql-read-replica############################################################
enabled_replica = false
replica_instance_class = "db.t3.small"

############################DB parameter group######################
mysql_family = "mysql8.0"
#mysql_parameter_group_name = "vtx-uat-8-0-parametergp"
##If the parameter group name is already there in the AWS account and DBA team would like to use that same parameter group then we need to mention that name. If parameter group name is not mentioned then terraform will create a parameter group with "environment name".

##############################DB option group#######################
mysql_major_engine_version = "8.0"

##################################################################EKS###################################################
eks_enabled = true
kubernetes_version = "1.27"
eks_allowed_cidr_blocks_cluster = ["10.238.224.0/24", "10.238.72.0/24", "172.25.80.0/20", "10.155.1.0/24", "10.155.4.0/24", "10.254.0.0/16", "172.71.80.0/20", "10.238.21.43/32"]

node_group_enabled = true
node_groups = {
  product-shared = {
        node_group_name           = "product-shared"
        node_group_instance_type = "c7i.4xlarge"
        kubernetes_labels         = {
                   Group = "product-shared"
                }
        taints                    = []
        node_group_capacity_type  = "ON_DEMAND"
        ami_type                  = "AL2_x86_64"
        ami_release_version       = "1.27.7-20231106"
        node_group_desired_size   = 4
        node_group_max_size       = 8
        node_group_min_size       = 2
        node_group_volume_size    = "100"
        node_group_volume_type    = "gp2"
        subnet_component_tag      = "eks-product-shared"  
    }
}

fargate_enabled = false
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
broker_node_instance_type = "kafka.m5.xlarge"
kafka_broker_number = 6
broker_node_ebs_volume_size = 200
configuration_server_properties = {
  "auto.create.topics.enable" = true
  "delete.topic.enable"       = true
}
schema_registries = {
  vortex = {
    name        = "vtxuat"
    description = "Schema registry for vortex UAT environment"
  }
}
schemas = {
  vortex = {
    schema_registry_name = "vortex"
    schema_name          = "vtxuat"
    description          = "Schema that contains all the Vortex UAT data"
    compatibility        = "FORWARD"
    schema_definition    = "{\"type\": \"record\", \"name\": \"r1\", \"fields\": [ {\"name\": \"f1\", \"type\": \"int\"}, {\"name\": \"f2\", \"type\": \"string\"} ]}"
  }
}
auto_saciling_storage_enabled = false
####################etcd-ec2###################################################################
etcd_ec2_enabled = true
etcd_ec2_instance_count = 3
etcd_ec2_ami            = "ami-04f178e9f970f279e"
etcd_ec2_instance_type  = "r6i.large"
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
    device_name = "/dev/sdb"
    volume_type = "gp3"
    volume_size = 1024
    iops = 5000
    throughput  = 200
    encrypted   = true
    delete_on_termination = true
  }
]
instance_tags = { "snapshot" = true }
key_name = "vtxpay-uat-etcd"
####################es-ec2###################################################################
es_ec2_enabled ="false"
es_ec2_instance_count = 4
es_ec2_ami            = "ami-04f178e9f970f279e"
es_ec2_instance_type  = "r6i.xlarge"
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
    volume_size = 1024
    iops = 5000
    throughput  = 200
    encrypted   = true
    delete_on_termination = true
  }
]

#instance_tags = { "snapshot" = true }
#key_name = ""

################################es-nlb#######################################################################
es_nlb_enabled = "false"
es_nlb_https_listeners = [
       {  
         port = 443
         protocol = "TLS"
         target_group_index = 0
         certificate_arn = "arn:aws:acm:us-east-1:388050911545:certificate/a970d6e8-37fc-4a5a-b6cf-340c76ba02b5"
       }
]
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
