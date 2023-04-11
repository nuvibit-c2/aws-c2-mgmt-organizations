# ---------------------------------------------------------------------------------------------------------------------
# ¦ DATA
# ---------------------------------------------------------------------------------------------------------------------
data "aws_organizations_organization" "current" {}
data "aws_organizations_resource_tags" "account" {
  for_each = {
    for a in data.aws_organizations_organization.current.accounts : a.id => a
    if a.status == "ACTIVE"
  }

  resource_id = each.key
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ LOCALS
# ---------------------------------------------------------------------------------------------------------------------
locals {
  active_org_accounts = [
    for a in data.aws_organizations_resource_tags.account : a.resource_id
  ]

  sso_permission_sets = [
    {
      name : "AdministratorAccess"
      description : "This permission set grants full admin access"
      session_duration : 10
      inline_policy_json : ""
      managed_policies : [
        {
          managed_by : "aws"
          policy_name : "AdministratorAccess"
          policy_path : "/"
        }
      ]
      boundary_policy : {}
    },
    {
      name : "OrgBilling"
      description : "This permission set grants organizational billing access"
      session_duration : 10
      inline_policy_json : ""
      managed_policies : [
        {
          managed_by : "aws"
          policy_name : "Billing"
          policy_path : "/job-function/"
        },
        {
          managed_by : "aws"
          policy_name : "ViewOnlyAccess"
          policy_path : "/job-function/"
        }
      ]
      boundary_policy : {}
    },
    {
      name : "SupportUser"
      description : "This permission set grants access for support users"
      session_duration : 10
      inline_policy_json : ""
      managed_policies : [
        {
          managed_by : "aws"
          policy_name : "SupportUser"
          policy_path : "/job-function/"
        },
        {
          managed_by : "aws"
          policy_name : "ReadOnlyAccess"
          policy_path : "/"
        }
      ]
      boundary_policy : {}
    }
  ]

  sso_account_assignments = [for account in local.active_org_accounts :
    {
      account_id = account
      permissions = [
        {
          permission_set_name : "AdministratorAccess"
          users : [
            "stefano.franco@nuvibit.com",
            # "jonas.saegesser@nuvibit.com",
            # "andreas.moor@nuvibit.com",
            # "roman.plessl@nuvibit.com",
            # "michael.ullrich@nuvibit.com",
          ]
          groups = []
        },
        {
          permission_set_name : "OrgBilling"
          users : [
            "christoph.siegrist@nuvibit.com",
          ]
          groups = []
        },
        {
          permission_set_name : "SupportUser"
          users : [
            "stefano.franco@nuvibit.com",
            "jonas.saegesser@nuvibit.com",
            "andreas.moor@nuvibit.com",
            "roman.plessl@nuvibit.com",
            "michael.ullrich@nuvibit.com",
          ]
          groups = []
        }
      ]
    }
  ]
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ IAM IDENTITY CENTER - SSO
# ---------------------------------------------------------------------------------------------------------------------
module "identity_center" {
  source = "github.com/nuvibit/terraform-aws-ntc-identity-center?ref=feat-init"

  permission_sets     = local.sso_permission_sets
  account_assignments = local.sso_account_assignments

  providers = {
    aws = aws.euc1
  }
}