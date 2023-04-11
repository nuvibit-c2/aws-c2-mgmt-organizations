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
    #   scp_name               = "DenyAll",
    #   scp_target_ou_paths    = ["/root/workloads/prod"]
    #   scp_target_account_ids = []
    #   scp_content_json       = data.aws_iam_policy_document.scp_allow_all.json
    # }
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
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ ORGANIZATION
# ---------------------------------------------------------------------------------------------------------------------
module "organization" {
  source = "github.com/nuvibit/terraform-aws-ntc-organization?ref=feat-init"

  service_access_principals = local.service_access_principals
  organizational_unit_paths = local.organizational_unit_paths
  service_control_policies  = local.service_control_policies
  delegated_administrators  = local.delegated_administrators

  providers = {
    aws = aws.euc1
  }
}