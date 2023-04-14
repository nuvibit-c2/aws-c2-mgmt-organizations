# ---------------------------------------------------------------------------------------------------------------------
# ¦ LOCALS
# ---------------------------------------------------------------------------------------------------------------------
locals {
  # list of services which should be enabled in Organizations
  service_access_principals = [
    "cloudtrail.amazonaws.com",
    "securityhub.amazonaws.com",
    "config.amazonaws.com",
    "guardduty.amazonaws.com",
    "sso.amazonaws.com",
    "ipam.amazonaws.com"
  ]

  # list of services which should be delegated to an administrator account
  delegated_administrators = [
    {
      service_principal = "securityhub.amazonaws.com"
      admin_account_id  = local.organization_account_ids["aws-c2-security"]
    },
    {
      service_principal = "config.amazonaws.com"
      admin_account_id  = local.organization_account_ids["aws-c2-security"]
    },
    {
      service_principal = "guardduty.amazonaws.com"
      admin_account_id  = local.organization_account_ids["aws-c2-security"]
    }
  ]

  # list of nested (up to 5 levels) organizational units
  organizational_unit_paths = [
    "/root/infrastructure",
    "/root/security",
    "/root/sandbox",
    "/root/suspended",
    "/root/workloads",
    "/root/workloads/prod",
    "/root/workloads/sdlc"
  ]

  # list of SCPs which should be attached to multiple organizational units and/or accounts
  service_control_policies = [
    {
      policy_name        = "scp_deny_leaving_organization",
      target_ou_paths    = ["/root"]
      target_account_ids = []
      policy_json        = file("${path.module}/scp-examples/scp_deny_leaving_organization.json")
    }
  ]

  # account map can be stored as HCL map or alternatively as JSON for easy integration e.g. self service portal integration via git
  organization_accounts = lookup(jsondecode(file("${path.module}/ntc_organization_accounts.json")), "organization_accounts", false)

  # original account map enriched with addition values e.g. account id
  organization_account_ids = module.organization.organization_account_ids
  organization_accounts_enriched = [
    for account in local.organization_accounts : merge(account,
      {
        account_id = local.organization_account_ids[account.account_name]
      }
    )
  ]
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ NTC ORGANIZATION
# ---------------------------------------------------------------------------------------------------------------------
module "organization" {
  source = "github.com/nuvibit-terraform-collection/terraform-aws-ntc-organization?ref=beta"

  service_access_principals = local.service_access_principals
  delegated_administrators  = local.delegated_administrators
  organizational_unit_paths = local.organizational_unit_paths
  service_control_policies  = local.service_control_policies
  organization_accounts     = local.organization_accounts

  providers = {
    aws = aws.euc1
  }
}