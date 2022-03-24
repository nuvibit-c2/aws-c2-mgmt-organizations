output "region" {
  value = data.aws_region.current.name
}

output "org_id" {
  value = data.aws_organizations_organization.current.id
}

output "account_id" {
  value = data.aws_caller_identity.current.account_id
}
