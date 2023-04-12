# ---------------------------------------------------------------------------------------------------------------------
# ¦ DATA
# ---------------------------------------------------------------------------------------------------------------------
data "aws_iam_policy_document" "scp_allow_all" {
  statement {
    effect    = "Allow"
    actions   = ["*"]
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
    "sso.amazonaws.com"
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
    "/root/workloads",
    "/root/workloads/prod",
    "/root/workloads/nonprod"
  ]

  service_control_policies = [
    # {
    #   policy_name        = "AllowAll",
    #   target_ou_paths    = ["/root/workloads/prod"]
    #   target_account_ids = []
    #   policy_json        = data.aws_iam_policy_document.scp_allow_all.json
    # }
  ]

  member_accounts = [
    # {
    #   account_name      = "aws-c2-1681243342"
    #   account_email     = "accounts+aws-c2-1681243342@nuvibit.com"
    #   ou_path           = "/root"
    #   close_on_deletion = true
    #   account_tags = {
    #     "Owner" : "stefano.franco@nuvibit.com"
    #   }
    # }
  ]
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ ORGANIZATION
# ---------------------------------------------------------------------------------------------------------------------
module "organization" {
  source = "github.com/nuvibit/terraform-aws-ntc-organization?ref=beta"

  service_access_principals = local.service_access_principals
  delegated_administrators  = local.delegated_administrators
  organizational_unit_paths = local.organizational_unit_paths
  service_control_policies  = local.service_control_policies
  member_accounts           = local.member_accounts

  providers = {
    aws = aws.euc1
  }
}