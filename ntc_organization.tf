# ---------------------------------------------------------------------------------------------------------------------
# ¦ DATA
# ---------------------------------------------------------------------------------------------------------------------
data "aws_iam_policy_document" "scp_deny_leave_org" {
  statement {
    effect    = "Deny"
    actions   = ["organizations:LeaveOrganization"]
    resources = ["*"]
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ LOCALS
# ---------------------------------------------------------------------------------------------------------------------
locals {
  service_access_principals = [
    "cloudtrail.amazonaws.com",
    "securityhub.amazonaws.com",
    "config.amazonaws.com",
    "guardduty.amazonaws.com",
    "sso.amazonaws.com",
    "ipam.amazonaws.com"
  ]

  delegated_administrators = [
    {
      service_principal = "securityhub.amazonaws.com"
      admin_account_id  = "769269768678"
    },
    {
      service_principal = "config.amazonaws.com"
      admin_account_id  = "769269768678"
    },
    {
      service_principal = "guardduty.amazonaws.com"
      admin_account_id  = "769269768678"
    }
  ]

  organizational_unit_paths = [
    "/root/infrastructure",
    "/root/security",
    "/root/sandbox",
    "/root/suspended",
    "/root/workloads",
    "/root/workloads/prod",
    "/root/workloads/sdlc"
  ]

  service_control_policies = [
    {
      policy_name        = "DenyLeaveOrg",
      target_ou_paths    = ["/root"]
      target_account_ids = []
      policy_json        = data.aws_iam_policy_document.scp_deny_leave_org.json
    }
  ]
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ ORGANIZATION
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