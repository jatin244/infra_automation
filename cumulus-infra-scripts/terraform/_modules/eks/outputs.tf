output "eks_cluster_security_group_id" {
  value       = var.enabled ? module.eks_cluster.security_group_id : null
  description = "ID of the EKS cluster Security Group."
}

output "eks_cluster_security_group_arn" {
  value       = var.enabled ? module.eks_cluster.security_group_arn : null
  description = "ARN of the EKS cluster Security Group."
}

output "eks_cluster_security_group_name" {
  value       = var.enabled ? module.eks_cluster.security_group_name : null
  description = "Name of the EKS cluster Security Group."
}

output "eks_cluster_id" {
  value       = var.enabled ? module.eks_cluster.eks_cluster_id : null
  description = "The name of the cluster."
}

output "eks_cluster_arn" {
  value       = var.enabled ? module.eks_cluster.eks_cluster_arn : null
  description = "The Amazon Resource Name (ARN) of the cluster."
}

output "eks_cluster_certificate_authority_data" {
  value       = var.enabled ? module.eks_cluster.eks_cluster_certificate_authority_data : null
  description = "The base64 encoded certificate data required to communicate with the cluster."
}

output "eks_cluster_endpoint" {
  value       = var.enabled ? module.eks_cluster.eks_cluster_endpoint : null
  description = "The endpoint for the Kubernetes API server."
}

output "eks_cluster_version" {
  value       = var.enabled ? module.eks_cluster.eks_cluster_version : null
  description = "The Kubernetes server version of the cluster."
}

output "workers_launch_template_id" {
  value       = var.enabled ? module.eks_workers.launch_template_id : null
  description = "ID of the launch template."
}

output "workers_launch_template_arn" {
  value       = var.enabled ? module.eks_workers.launch_template_arn : null
  description = "ARN of the launch template."
}

output "workers_autoscaling_group_id" {
  value       = var.enabled ? module.eks_workers.autoscaling_group_id : null
  description = "The AutoScaling Group ID."
}

output "workers_autoscaling_group_name" {
  value       = var.enabled ? module.eks_workers.autoscaling_group_name : null
  description = "The AutoScaling Group name."
}

output "workers_autoscaling_group_arn" {
  value       = var.enabled ? module.eks_workers.autoscaling_group_arn : null
  description = "ARN of the AutoScaling Group."
}

output "workers_autoscaling_group_min_size" {
  value       = var.enabled ? module.eks_workers.autoscaling_group_min_size : null
  description = "The minimum size of the AutoScaling Group."
}

output "workers_autoscaling_group_max_size" {
  value       = var.enabled ? module.eks_workers.autoscaling_group_max_size : null
  description = "The maximum size of the AutoScaling Group."
}

output "workers_autoscaling_group_desired_capacity" {
  value       = var.enabled ? module.eks_workers.autoscaling_group_desired_capacity : null
  description = "The number of Amazon EC2 instances that should be running in the group."
}

output "workers_autoscaling_group_default_cooldown" {
  value       = var.enabled ? module.eks_workers.autoscaling_group_default_cooldown : null
  description = "Time between a scaling activity and the succeeding scaling activity."
}

output "workers_autoscaling_group_health_check_grace_period" {
  value       = var.enabled ? module.eks_workers.autoscaling_group_health_check_grace_period : null
  description = "Time after instance comes into service before checking health."
}

output "workers_autoscaling_group_health_check_type" {
  value       = var.enabled ? module.eks_workers.autoscaling_group_health_check_type : null
  description = "`EC2` or `ELB`. Controls how health checking is done."
}

output "workers_security_group_id" {
  value       = var.enabled ? module.eks_workers.security_group_id : null
  description = "ID of the worker nodes Security Group."
}

output "workers_security_group_arn" {
  value       = var.enabled ? module.eks_workers.security_group_arn : null
  description = "ARN of the worker nodes Security Group."
}

output "workers_security_group_name" {
  value       = var.enabled ? module.eks_workers.security_group_name : null
  description = "Name of the worker nodes Security Group."
}

output "eks_fargate_arn" {
  value       = var.enabled ? module.eks_workers.eks_fargate_arn : null
  description = "Amazon Resource Name (ARN) of the EKS Fargate Profile."
}

output "eks_fargate_id" {
  value       = var.enabled ? module.eks_workers.eks_fargate_id : null
  description = "EKS Cluster name and EKS Fargate Profile name separated by a colon (:)."
}

output "tags" {
  value       = var.enabled ? module.eks_cluster.tags : null
  description = "A mapping of tags to assign to the resource."
}

output "kubernetes_config_map_id" {
  description = "ID of `aws-auth` Kubernetes ConfigMap"
  value       = var.enabled ? module.eks_cluster.kubernetes_config_map_id : null
}

output "iam_role_arn" {
  value       = var.enabled ? join("", aws_iam_role.default.*.arn) : null
  description = "ARN of the worker nodes IAM role."
}

#output "eks_node_group_id" {
#  value       = var.enabled ? module.node_group.eks_node_group_id : null
#  description = "EKS Cluster name and EKS Node Group name separated by a colon"
#}
#
#output "eks_node_group_arn" {
#  value       = var.enabled ? module.node_group.eks_node_group_arn : null
#  description = "Amazon Resource Name (ARN) of the EKS Node Group"
#}
#
#output "eks_node_group_resources" {
#  value       = var.enabled ? module.node_group.eks_node_group_resources : null
#  description = "List of objects containing information about underlying resources of the EKS Node Group"
#}
#
#output "eks_node_group_status" {
#  value       = var.enabled ? module.node_group.eks_node_group_status : null
#  description = "Status of the EKS Node Group"
#}
