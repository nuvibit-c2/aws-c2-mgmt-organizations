# ---------------------------------------------------------------------------------------------------------------------
# ¦ LOCALS
# ---------------------------------------------------------------------------------------------------------------------
locals {
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

  sso_account_assignments = [for account in local.organization_accounts_enriched :
    {
      account_id = account.account_id
      permissions = [
        {
          permission_set_name : "AdministratorAccess"
          users : account.sso_admin_users
          groups = []
        },
        {
          permission_set_name : "OrgBilling"
          users : account.sso_billing_users
          groups = []
        },
        {
          permission_set_name : "SupportUser"
          users : account.sso_support_users
          groups = []
        }
      ]
    }
    # only add sso permissions if account is not suspended
    if account.ou_path != "/root/suspended" && account.account_status == "ACTIVE"
  ]
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ IAM IDENTITY CENTER - SSO
# ---------------------------------------------------------------------------------------------------------------------
module "identity_center" {
  source = "github.com/nuvibit/terraform-aws-ntc-identity-center?ref=beta"

  permission_sets     = local.sso_permission_sets
  account_assignments = local.sso_account_assignments

  providers = {
    aws = aws.euc1
  }
}