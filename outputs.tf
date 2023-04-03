output "region" {
  description = "The current region name"
  value       = data.aws_region.current.name
}

output "account_id" {
  description = "The current account id"
  value       = data.aws_caller_identity.current.account_id
}

output "core_parameters" {
  description = "Map of all core parameters"
  value       = local.core_parameters
}