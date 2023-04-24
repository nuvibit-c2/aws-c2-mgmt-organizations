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
      admin_account_id  = "769269768678" # aws-c2-security
    },
    {
      service_principal = "config.amazonaws.com"
      admin_account_id  = "769269768678" # aws-c2-security
    },
    {
      service_principal = "guardduty.amazonaws.com"
      admin_account_id  = "769269768678" # aws-c2-security
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
    },
    {
      policy_name        = "scp_deny_all_suspended",
      target_ou_paths    = ["/root/suspended"]
      target_account_ids = []
      policy_json        = file("${path.module}/scp-examples/scp_deny_all_suspended.json")
    }
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

  providers = {
    aws = aws.euc1
  }
}