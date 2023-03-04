output "region" {
  description = "The current region name"
  value       = data.aws_region.current.name
}

output "account_id" {
  description = "The current account id"
  value       = data.aws_caller_identity.current.account_id
}

output "tenant_ou_ids" {
  description = "A List of tenant ou ids"
  value       = module.main_config.tenant_ou_ids
}

output "organization_root_id" {
  description = "The organization root id"
  value       = module.main_config.organization_root_id
}

output "account_parameters" {
  description = "The account parameter values"
  value       = try(module.org_mgmt_parameters.parameters, {})
}

output "sso_permission_sets_map" {
  description = "Map of permission sets configured to be used with AWS SSO."
  value = module.sso_identity_center.sso_permission_sets_map
}

output "sso_user_assignments_map" {
  description = "Map of permission sets configured to be used with AWS SSO."
  value = module.sso_identity_center.sso_user_assignments_map
}

output "sso_group_assignments_map" {
  description = "Map of group assignments in AWS SSO."
  value = module.sso_identity_center.sso_group_assignments_map
}