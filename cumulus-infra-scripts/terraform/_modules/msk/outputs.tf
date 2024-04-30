output "cluster_arn" {
  value       = try(aws_msk_cluster.msk-cluster[0].arn, "")
  description = "Amazon Resource Name (ARN) of the MSK cluster"
}

output "current_version" {
  value       = try(aws_msk_cluster.msk-cluster[0].current_version, "")
  description = "Current version of the MSK Cluster used for updates, e.g. `K13V1IB3VIYZZH`"
}

output "configuration_arn" {
  value       = try(aws_msk_configuration.this[0].arn, "")
  description = "Amazon Resource Name (ARN) of the configuration"
}

output "configuration_latest_revision" {
  value       = try(aws_msk_configuration.this[0].latest_revision, "")
  description = "Latest revision of the configuration"
}

output "scram_secret_association_id" {
  value       = try(aws_msk_scram_secret_association.this[0].id, "")
  description = "Amazon Resource Name (ARN) of the MSK cluster"
}

output "bootstrap_brokers_tls" {
  value       = join("", aws_msk_cluster.msk-cluster.*.bootstrap_brokers_tls)
  description = "One or more DNS names (or IP addresses) and TLS port pairs. For example"
}
output "bootstrap_endpoints" {
  value       = local.broker_endpoints
  description = "DNS names for all brokers"
}
