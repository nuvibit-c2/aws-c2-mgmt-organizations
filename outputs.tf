output "default_region" {
  description = "The default region name"
  value       = local.default_region
}

output "account_id" {
  description = "The current account id"
  value       = local.current_account_id
}

output "aws_partition" {
  description = "The current AWS partition"
  value       = local.current_partition
}

output "current_partition_dns_suffix" {
  description = "The current AWS partition DNS suffix"
  value = local.current_partition_dns_suffix
}

output "ntc_parameters" {
  description = "Map of all ntc parameters"
  value       = local.ntc_parameters
}