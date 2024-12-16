locals {
  # some services like 'aws config' and 'iam access analyzer' are delegated once and not for each region
  global_delegated_administrators = [
    {
      service_principal = "config.amazonaws.com"
      admin_account_id  = local.ntc_parameters["mgmt-account-factory"]["core_accounts"]["aws-c2-security"]
    },
    {
      service_principal = "access-analyzer.amazonaws.com"
      admin_account_id  = local.ntc_parameters["mgmt-account-factory"]["core_accounts"]["aws-c2-security"]
    },
  ]

  # some services like amazon guardduty need to be delegated for each region
  regional_delegated_administrators = [
    {
      service_principal = "securityhub.amazonaws.com"
      admin_account_id  = local.ntc_parameters["mgmt-account-factory"]["core_accounts"]["aws-c2-security"]
    },
    {
      service_principal = "guardduty.amazonaws.com"
      admin_account_id  = local.ntc_parameters["mgmt-account-factory"]["core_accounts"]["aws-c2-security"]
    },
    {
      service_principal = "inspector2.amazonaws.com"
      admin_account_id  = local.ntc_parameters["mgmt-account-factory"]["core_accounts"]["aws-c2-security"]
    },
  ]
}

# organizations integration of iam access analyzer requires a service linked role in org management account
# this role gets created when creating up an access analyzer for the first time (analyzer can be deleted afterwards)
# https://docs.aws.amazon.com/IAM/latest/UserGuide/access-analyzer-using-service-linked-roles.html#create-slr

# resource "aws_accessanalyzer_analyzer" "init" {
#   analyzer_name = "init-service-linked-role"
# }

# ---------------------------------------------------------------------------------------------------------------------
# ¦ NTC ORGANIZATIONS - ADMIN DELEGATIONS
# ---------------------------------------------------------------------------------------------------------------------
module "ntc_delegated_admins_euc1" {
  source = "github.com/nuvibit-terraform-collection/terraform-aws-ntc-organizations//modules/regional-admin-delegations?ref=1.3.0"

  delegated_administrators = concat(local.global_delegated_administrators, local.regional_delegated_administrators)

  providers = {
    aws = aws.euc1
  }
}

module "ntc_delegated_admins_euc2" {
  source = "github.com/nuvibit-terraform-collection/terraform-aws-ntc-organizations//modules/regional-admin-delegations?ref=1.3.0"

  delegated_administrators = local.regional_delegated_administrators

  providers = {
    aws = aws.euc2
  }
}

module "ntc_delegated_admins_use1" {
  source = "github.com/nuvibit-terraform-collection/terraform-aws-ntc-organizations//modules/regional-admin-delegations?ref=1.3.0"

  delegated_administrators = local.regional_delegated_administrators

  providers = {
    aws = aws.use1
  }
}
