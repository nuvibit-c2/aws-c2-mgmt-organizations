removed {
  from = aws_iam_service_linked_role.access_analyzer
  lifecycle {
    destroy = false
  }
}

# state migration for global admin delegations
moved {
  from = module.ntc_delegated_admins_euc1.aws_organizations_delegated_administrator.ntc_delegated_admin["access-analyzer.amazonaws.com"]
  to   = module.ntc_organizations.module.admin_delegations.aws_organizations_delegated_administrator.ntc_delegated_admin["access-analyzer.amazonaws.com"]
}

moved {
  from = module.ntc_delegated_admins_euc1.aws_organizations_delegated_administrator.ntc_delegated_admin["backup.amazonaws.com"]
  to   = module.ntc_organizations.module.admin_delegations.aws_organizations_delegated_administrator.ntc_delegated_admin["backup.amazonaws.com"]
}

moved {
  from = module.ntc_delegated_admins_euc1.aws_organizations_delegated_administrator.ntc_delegated_admin["config.amazonaws.com"]
  to   = module.ntc_organizations.module.admin_delegations.aws_organizations_delegated_administrator.ntc_delegated_admin["config.amazonaws.com"]
}

# state migration for regional admin delegations (eu-central-1)
moved {
  from = module.ntc_delegated_admins_euc1.aws_guardduty_detector.ntc_guardduty[0]
  to   = module.ntc_organizations.module.admin_delegations.aws_guardduty_detector.ntc_guardduty["eu-central-1"]
}

moved {
  from = module.ntc_delegated_admins_euc1.aws_guardduty_organization_admin_account.ntc_guardduty[0]
  to   = module.ntc_organizations.module.admin_delegations.aws_guardduty_organization_admin_account.ntc_guardduty["eu-central-1"]
}

moved {
  from = module.ntc_delegated_admins_euc1.aws_inspector2_delegated_admin_account.ntc_inspector[0]
  to   = module.ntc_organizations.module.admin_delegations.aws_inspector2_delegated_admin_account.ntc_inspector["eu-central-1"]
}

moved {
  from = module.ntc_delegated_admins_euc1.aws_securityhub_account.ntc_security_hub[0]
  to   = module.ntc_organizations.module.admin_delegations.aws_securityhub_account.ntc_security_hub["eu-central-1"]
}

moved {
  from = module.ntc_delegated_admins_euc1.aws_securityhub_organization_admin_account.ntc_security_hub[0]
  to   = module.ntc_organizations.module.admin_delegations.aws_securityhub_organization_admin_account.ntc_security_hub["eu-central-1"]
}

# state migration for regional admin delegations (eu-central-2)
moved {
  from = module.ntc_delegated_admins_euc2.aws_guardduty_detector.ntc_guardduty[0]
  to   = module.ntc_organizations.module.admin_delegations.aws_guardduty_detector.ntc_guardduty["eu-central-2"]
}

moved {
  from = module.ntc_delegated_admins_euc2.aws_guardduty_organization_admin_account.ntc_guardduty[0]
  to   = module.ntc_organizations.module.admin_delegations.aws_guardduty_organization_admin_account.ntc_guardduty["eu-central-2"]
}

moved {
  from = module.ntc_delegated_admins_euc2.aws_inspector2_delegated_admin_account.ntc_inspector[0]
  to   = module.ntc_organizations.module.admin_delegations.aws_inspector2_delegated_admin_account.ntc_inspector["eu-central-2"]
}

moved {
  from = module.ntc_delegated_admins_euc2.aws_securityhub_account.ntc_security_hub[0]
  to   = module.ntc_organizations.module.admin_delegations.aws_securityhub_account.ntc_security_hub["eu-central-2"]
}

moved {
  from = module.ntc_delegated_admins_euc2.aws_securityhub_organization_admin_account.ntc_security_hub[0]
  to   = module.ntc_organizations.module.admin_delegations.aws_securityhub_organization_admin_account.ntc_security_hub["eu-central-2"]
}

# state migration for regional admin delegations (us-east-1)
moved {
  from = module.ntc_delegated_admins_use1.aws_guardduty_detector.ntc_guardduty[0]
  to   = module.ntc_organizations.module.admin_delegations.aws_guardduty_detector.ntc_guardduty["us-east-1"]
}

moved {
  from = module.ntc_delegated_admins_use1.aws_guardduty_organization_admin_account.ntc_guardduty[0]
  to   = module.ntc_organizations.module.admin_delegations.aws_guardduty_organization_admin_account.ntc_guardduty["us-east-1"]
}

moved {
  from = module.ntc_delegated_admins_use1.aws_inspector2_delegated_admin_account.ntc_inspector[0]
  to   = module.ntc_organizations.module.admin_delegations.aws_inspector2_delegated_admin_account.ntc_inspector["us-east-1"]
}

moved {
  from = module.ntc_delegated_admins_use1.aws_securityhub_account.ntc_security_hub[0]
  to   = module.ntc_organizations.module.admin_delegations.aws_securityhub_account.ntc_security_hub["us-east-1"]
}

moved {
  from = module.ntc_delegated_admins_use1.aws_securityhub_organization_admin_account.ntc_security_hub[0]
  to   = module.ntc_organizations.module.admin_delegations.aws_securityhub_organization_admin_account.ntc_security_hub["us-east-1"]
}
