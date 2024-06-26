output "launch_template_id" {
  value       = module.autoscale_group.launch_template_id
  description = "The ID of the launch template."
}

output "launch_template_arn" {
  value       = module.autoscale_group.launch_template_arn
  description = "ARN of the launch template."
}

output "autoscaling_group_id" {
  value       = module.autoscale_group.autoscaling_group_id
  description = "The AutoScaling Group ID."
}

output "autoscaling_group_name" {
  value       = module.autoscale_group.autoscaling_group_name
  description = "The AutoScaling Group name."
}

output "autoscaling_group_arn" {
  value       = module.autoscale_group.autoscaling_group_arn
  description = "ARN of the AutoScaling Group."
}

output "autoscaling_group_min_size" {
  value       = module.autoscale_group.autoscaling_group_min_size
  description = "The minimum size of the AutoScaling Group."
}

output "autoscaling_group_max_size" {
  value       = module.autoscale_group.autoscaling_group_max_size
  description = "The maximum size of the AutoScaling Group."
}

output "autoscaling_group_desired_capacity" {
  value       = module.autoscale_group.autoscaling_group_desired_capacity
  description = "The number of Amazon EC2 instances that should be running in the group."
}

output "autoscaling_group_default_cooldown" {
  value       = module.autoscale_group.autoscaling_group_default_cooldown
  description = "Time between a scaling activity and the succeeding scaling activity."
}

output "autoscaling_group_health_check_grace_period" {
  value       = module.autoscale_group.autoscaling_group_health_check_grace_period
  description = "Time after instance comes into service before checking health."
}

output "autoscaling_group_health_check_type" {
  value       = module.autoscale_group.autoscaling_group_health_check_type
  description = "`EC2` or `ELB`. Controls how health checking is done."
}

output "security_group_id" {
  value       = join("", aws_security_group.default.*.id)
  description = "ID of the worker nodes Security Group."
}

output "security_group_arn" {
  value       = join("", aws_security_group.default.*.arn)
  description = "ARN of the worker nodes Security Group."
}

output "security_group_name" {
  value       = join("", aws_security_group.default.*.name)
  description = "Name of the worker nodes Security Group."
}

output "eks_fargate_arn" {
  value = tomap({
    for k, inst in aws_eks_fargate_profile.default : k => inst.arn
  })
  description = "Amazon Resource Name (ARN) of the EKS Fargate Profile."
}

output "eks_fargate_id" {
  value = tomap({
    for k, inst in aws_eks_fargate_profile.default : k => inst.id
  })
  description = "EKS Cluster name and EKS Fargate Profile name separated by a colon (:)."
}

output "eks_fargate_role_arn" {
  value       = join("", aws_iam_role.fargate_role.*.arn)
  description = "AWS EKS Fargate role arn"
}

output "eks_fargate_role_name" {
  value       = join("", aws_iam_role.fargate_role.*.name)
  description = "AWS EKS Fargate role name"
}
