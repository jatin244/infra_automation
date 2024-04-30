#######################################################security-group#########################################################
eks_sg_cidr_blocks       = ["10.238.224.0/24", "10.238.72.0/24", "172.25.80.0/20", "10.155.1.0/24", "10.155.4.0/24", "10.254.0.0/16", "172.71.80.0/20", "10.238.21.43/32"] ##eks-sg-cidr##
redis_sg_cidr_blocks     = ["10.238.224.0/24", "10.238.72.0/24", "172.25.80.0/20", "10.155.1.0/24", "10.155.4.0/24", "10.254.0.0/16", "172.71.80.0/20"]
mysql_sg_cidr_blocks     = ["10.238.76.0/24", "10.238.224.0/24", "10.238.72.0/24", "172.25.80.0/20", "10.155.1.0/24", "10.155.4.0/24", "10.254.0.0/16", "172.71.80.0/20", "172.26.0.0/20"]
msk_sg_cidr_blocks       = ["10.238.224.0/24", "10.238.72.0/24", "172.25.80.0/20", "10.155.1.0/24", "10.155.4.0/24", "10.254.0.0/16", "172.71.80.0/20"]
ssh_sg_cidr_blocks       = ["10.238.224.0/24", "10.238.72.0/24", "172.25.80.0/20", "10.155.1.0/24", "10.155.4.0/24", "10.254.0.0/16", "172.71.80.0/20"]
etcd_ec2_sg_cidr_blocks  = ["10.238.224.0/24", "10.238.72.0/24", "172.25.80.0/20", "10.155.1.0/24", "10.155.4.0/24", "10.254.0.0/16", "172.71.80.0/20"]
es_ec2_sg_cidr_blocks    = ["10.238.224.0/24", "10.238.72.0/24", "172.25.80.0/20", "10.155.1.0/24", "10.155.4.0/24", "10.254.0.0/16", "172.71.80.0/20"]
es_nlb_sg_cidr_blocks    = ["10.238.224.0/24", "10.238.72.0/24", "172.25.80.0/20", "10.155.1.0/24", "10.155.4.0/24", "10.254.0.0/16", "172.71.80.0/20"]

#Workspace CS Admin - "10.155.1.0/24", "10.155.4.0/24"
#CS Non-Prod Ops VPC - "172.25.80.0/20"
#AS NonProd Ops VPC - "172.71.80.0/20"
#DB Ops - "172.26.0.0/20"
#VPN - "10.254.0.0/16"
#VDI Admins  - "10.238.72.0/24"
#VDI AS Team - "10.238.224.0/24"
#VDI DB Team -  "10.238.76.0/24"
#Octopus - "10.238.21.43/32"

#######################################################secrets_manager##################################################
recovery_window_in_days = 0

##############################redis-cluster#############################################################################
redis_engine_version = "6.2"
redis_node_type      = "cache.r6g.xlarge"

#######################################################mysql############################################################
mysql_engine_version    = "8.0.28"
mysql_instance_class    = "db.r6g.2xlarge"
mysql_allocated_storage = 500

#######################################################mysql-read-replica############################################################
enabled_replica = false
replica_instance_class = "db.t3.small"

############################DB parameter group######################
mysql_family = "mysql8.0"

##############################DB option group#######################
mysql_major_engine_version = "8.0"

##################################################################EKS###################################################
kubernetes_version = "1.27"
eks_allowed_cidr_blocks_cluster = ["10.238.224.0/24", "10.238.72.0/24", "172.25.80.0/20", "10.155.1.0/24", "10.155.4.0/24", "10.254.0.0/16", "172.71.80.0/20", "10.238.21.43/32"]

fargate_profiles = {
  profile-default = {
    addon_name = "default"
    namespace  = "default"
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
    name        = "vxqa"
    description = "Schema registry for vortex QA"
  }
}
schemas = {
  vortex = {
    schema_registry_name = "vortex"
    schema_name          = "vxqa"
    description          = "Schema that contains all the Vortex QA data"
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
key_name = "vtxpa-qa-etcd"
####################es-ec2###################################################################
#es_ec2_instance_count = 4
#es_ec2_ami            = "ami-04f178e9f970f279e"
#es_ec2_instance_type  = "r6i.xlarge"
#es_ec2_root_block_device = [
#  {
#    volume_type           = "gp3"
#    volume_size           = 30
#    delete_on_termination = true
#    encrypted   = true
#  }
#]
#es_ec2_ebs_block_device = [
#  {
#    device_name = "/dev/sdb"
#    volume_type = "gp3"
#    volume_size = 1024
#    iops = 5000
#    throughput  = 200
#    encrypted   = true
#    delete_on_termination = true
#  }
#]
#
#instance_tags = { "snapshot" = true }
#key_name = "prth-cpx-prod-key"
#
################################es-nlb#######################################################################
#es_nlb_enabled = true
#es_nlb_https_listeners = [
#       {  
#         port = 443
#         protocol = "TLS"
#         target_group_index = 0
#         certificate_arn = "arn:aws:acm:us-east-1:388050911545:certificate/a970d6e8-37fc-4a5a-b6cf-340c76ba02b5"
#       }
#]
#es_nlb_http_tcp_listeners = [
#  { 
#    port               = 443
#    protocol           = "TCP"
#    target_group_index = 0
#  },
#  {
#    port               = 9200
#    protocol           = "TCP"
#    target_group_index = 1
#  },
#]
#es_target_groups = [
#  {
#    backend_protocol = "TCP"
#    backend_port     = 443
#    target_type      = "instance"
#    health_check     = {
#         path   = "/login"
#         matcher = "200-399"
#         protocol = "HTTPS"
#     }
#  },
#  {
#    backend_protocol = "TCP"
#    backend_port     = 9200
#    target_type      = "instance"
#  },
#]
