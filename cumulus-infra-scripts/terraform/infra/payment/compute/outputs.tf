######################################--eks--#################
output "eks_endpoint" {
  value = module.eks-cluster.eks_cluster_endpoint
}

######################################--DB--#################
output "db_username" {
  value       = module.mysql.db_instance_username
  sensitive   = true
  description = "Username for the master DB user."
}

output "db_password" {
  value       = module.mysql.db_instance_password
  sensitive   = true
  description = "Password for the master DB user."
}

output "db_endpoint" {
  value       = module.mysql.db_instance_endpoint
  description = "The connection endpoint in address:port format."
}

########################################################--msk--############################
output "mks_cluster" {
  value       = module.kafka.cluster_arn
  description = "Amazon Resource Name (ARN) of the MSK cluster."
}

output "es_dns_name" {
  value       = module.es_nlb.dns_name
  description = "DNS name of ES NLB."
}

output "es_instance_id" {
  value       = module.es_ec2.instance_id
  description = "Elasticsearch instance ID."
}

output "es_private_ip" {
  value       = module.es_ec2.private_ip
  description = "Private IP of Elasticsearch instance."
}
output "etcd_instance_id" {
  value       = module.etcd_ec2.instance_id
  description = "etcd instance ID."
}

output "etcd_private_ip" {
  value       = module.etcd_ec2.private_ip
  description = "Private IP of etcd instance."
}

