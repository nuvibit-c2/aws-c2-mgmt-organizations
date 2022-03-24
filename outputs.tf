output "region" {
  value = data.aws_region.current.name
}

output "org_id" {
  value = data.aws_organizations_organization.current.id
}

output "account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "tenant_ou_ids" {
  value = module.master_config.tenant_ou_ids
}

output "organization_root_id" {
  value = module.master_config.organization_root_id
}

output "branding_ou_id" {
  value = module.master_config.branding_ou_id
}

output "foundation_security_provisioner_role_arn" {
  value = module.foundation_security_provisioner.org_mgmt_provisioner_role_arn
}

output "aws_organizations_organization" {
  value = data.aws_organizations_organization.current
}

output "aws_organizations_organizational_units" {
  value = data.aws_organizations_organizational_units.ou
}

output "account_context" {
  value = module.account_context
}