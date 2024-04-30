#######################################################locals###########################################################
transit_gateway_id           = "tgw-01fa4f5c35fde259a"
transit_gateway_spoke_rtb_id = "tgw-rtb-098fb92091509884f"
transit_gateway_spoke_int_id = "tgw-rtb-011af727a55ef3e99"
egress_vpc_public_rtb_id     = "rtb-000d990229b4fc918"
ingress_vpc_cidr             = "172.20.192.0/20"
ingress_vpc_public_rtb_id    = "rtb-0f598da098c6c0f9d"
ingress_vpc_id               = "vpc-02a6330a96d8eda80"
ops_vpc_cidr                 = "172.20.96.0/20"
ops_vpc_id                   = "vpc-083eb7dbf43a53e29"
dns_vpc_id                   = "vpc-0d961bd68b1276be6"
hosted_zone_name             = "pr.prth.local"
hosted_zone_id               = "Z064902716FMNDDMQFCGA"

####################################################data-vpc############################################################
data_vpc_cidr = "10.49.0.0/20"

####################################################application-vpc#####################################################


#######################################################security-group#########################################################
eks_sg_cidr_blocks       = ["10.238.224.0/24", "10.238.72.0/24", "172.20.96.0/20", "10.155.1.0/24", "10.155.4.0/24", "10.254.151.0/24", "172.20.112.0/20", "10.238.21.43/32"] ##eks-sg-cidr##
redis_sg_cidr_blocks     = ["10.238.224.0/24", "10.238.72.0/24", "172.20.96.0/20", "10.155.1.0/24", "10.155.4.0/24", "10.254.151.0/24", "172.20.112.0/20"]
mysql_sg_cidr_blocks     = ["10.238.76.0/24", "10.238.224.0/24", "10.238.72.0/24", "172.20.96.0/20", "10.155.1.0/24", "10.155.4.0/24", "10.254.151.0/24", "172.20.112.0/20", "172.20.128.0/20"]
msk_sg_cidr_blocks       = ["10.238.224.0/24", "10.238.72.0/24", "172.20.96.0/20", "10.155.1.0/24", "10.155.4.0/24", "10.254.151.0/24", "172.20.112.0/20"]
ssh_sg_cidr_blocks       = ["10.238.224.0/24", "10.238.72.0/24", "172.20.96.0/20", "10.155.1.0/24", "10.155.4.0/24", "10.254.151.0/24", "172.20.112.0/20"]
etcd_ec2_sg_cidr_blocks  = ["10.238.224.0/24", "10.238.72.0/24", "172.20.96.0/20", "10.155.1.0/24", "10.155.4.0/24", "10.254.151.0/24", "172.20.112.0/20"]
es_ec2_sg_cidr_blocks    = ["10.238.224.0/24", "10.238.72.0/24", "172.20.96.0/20", "10.155.1.0/24", "10.155.4.0/24", "10.254.151.0/24", "172.20.112.0/20"]
es_nlb_sg_cidr_blocks    = ["10.238.224.0/24", "10.238.72.0/24", "172.20.96.0/20", "10.155.1.0/24", "10.155.4.0/24", "10.254.151.0/24", "172.20.112.0/20"]

#Workspace CS Admin - "10.155.1.0/24", "10.155.4.0/24"
#Prod Ops VPC - "172.20.96.0/20"
#AS Ops VPC - "172.20.112.0/20"
#DB Ops - "172.20.128.0/20"
#CSAdmin VPN - "10.254.151.0/24"
#VDI Admins  - "10.238.72.0/24"
#VDI AS Team - "10.238.224.0/24"
#VDI DB Team -  "10.238.76.0/24"

#######################################################secrets_manager##################################################
recovery_window_in_days = 0

##############################redis-cluster#############################################################################
redis_engine_version = "6.2"
redis_node_type      = "cache.r6g.2xlarge"

#######################################################mysql############################################################
mysql_engine_version    = "8.0.28"
mysql_instance_class    = "db.r6g.4xlarge"
mysql_allocated_storage = 2560
mysql_multi_az = true
mysql_backup_retention_period = 7
mysql_deletion_protection = true

#######################################################mysql-read-replica############################################################
enabled_replica = false
replica_instance_class = "db.t3.small"

############################DB parameter group######################
mysql_family = "mysql8.0"

##############################DB option group#######################
mysql_major_engine_version = "8.0"

##################################################################EKS###################################################
kubernetes_version = "1.27"
eks_allowed_cidr_blocks_cluster = ["10.238.224.0/24", "10.238.72.0/24", "172.20.96.0/20", "10.155.1.0/24", "10.155.4.0/24", "10.254.151.0/24", "172.20.112.0/20", "10.238.21.43/32"]

fargate_profiles = {
  profile-default = {
    addon_name = "default"
    namespace  = "defaultfargate"
  }
}

#######################################################kafka############################################################
kafka_version             = "2.6.2"
broker_node_instance_type = "kafka.m5.2xlarge"
kafka_broker_number = 6
broker_node_ebs_volume_size = 200
configuration_server_properties = {
  "auto.create.topics.enable" = true
  "delete.topic.enable"       = true
}
schema_registries = {
  vortex = {
    name        = "cpxsbox"
    description = "Schema registry for cpxprod"
  }
}
schemas = {
  vortex = {
    schema_registry_name = "vortex"
    schema_name          = "cpxsbox"
    description          = "Schema that contains all the cpxprod data"
    compatibility        = "FORWARD"
    schema_definition    = "{\"type\": \"record\", \"name\": \"r1\", \"fields\": [ {\"name\": \"f1\", \"type\": \"int\"}, {\"name\": \"f2\", \"type\": \"string\"} ]}"
  }
}
auto_saciling_storage_enabled = false
####################etcd-ec2###################################################################
etcd_ec2_enabled = false
etcd_ec2_instance_count = 2
etcd_ec2_ami            = "ami-04f178e9f970f279e"
etcd_ec2_instance_type  = "r6i.xlarge"
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

instance_tags = { "snapshot" = true }
key_name = "prth-cpx-sbox-key"

###############################es-nlb#######################################################################
es_nlb_enabled = true
#es_nlb_https_listeners = [
#       {  
#         port = 443
#         protocol = "TLS"
#         target_group_index = 0
#         certificate_arn = "arn:aws:acm:us-east-1:015987925177:certificate/95b686e7-e292-422a-9d35-03cd3abd4c47"
#       }
#]
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

