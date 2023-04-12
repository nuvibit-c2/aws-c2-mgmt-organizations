# ---------------------------------------------------------------------------------------------------------------------
# ¦ LOCALS
# ---------------------------------------------------------------------------------------------------------------------
locals {
  # global administrators permissions in all accounts
  global_sso_admin_users   = ["stefano.franco@nuvibit.com"]
  global_sso_billing_users = ["christoph.siegrist@nuvibit.com"]
  global_sso_support_users = [
    "stefano.franco@nuvibit.com",
    "jonas.saegesser@nuvibit.com",
    "andreas.moor@nuvibit.com",
    "roman.plessl@nuvibit.com",
    "michael.ullrich@nuvibit.com",
  ]

  # permissions sets which should be created and which can be referenced for account assignments
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

  # account assignments can be done for individual accounts or ideally an account map can be used to loop
  sso_account_assignments = [for account in local.organization_accounts_enriched :
    {
      account_id = account.account_id
      permissions = [
        {
          permission_set_name : "AdministratorAccess"
          # combine users with global permissions and users from account map
          users : concat(local.global_sso_admin_users, account.sso_admin_users)
          # groups can be referenced from account map or group names can be dynamically generated
          groups = []
          # groups = concat(local.global_sso_admin_groups, account.sso_admin_groups)
          # groups = ["sg-aws-admins-${account.account_id}"]
        },
        {
          permission_set_name : "OrgBilling"
          # combine users with global permissions and users from account map
          users : concat(local.global_sso_billing_users, account.sso_billing_users)
          # groups can be referenced from account map or group names can be dynamically generated
          groups = []
          # groups = concat(local.global_sso_billing_groups, account.sso_billing_groups)
          # groups = ["sg-aws-billing-${account.account_id}"]
        },
        {
          permission_set_name : "SupportUser"
          # combine users with global permissions and users from account map
          users : concat(local.global_sso_support_users, account.sso_support_users)
          # groups can be referenced from account map or group names can be dynamically generated
          groups = []
          # groups = concat(local.global_sso_support_groups, account.sso_support_groups)
          # groups = ["sg-aws-support-${account.account_id}"]
        }
      ]
    }
    # only add sso permissions if account is not suspended
    if account.ou_path != "/root/suspended" && account.account_status == "ACTIVE"
  ]
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ NTC IDENTITY CENTER - SSO
# ---------------------------------------------------------------------------------------------------------------------
module "identity_center" {
  source = "github.com/nuvibit-terraform-collection/terraform-aws-ntc-identity-center?ref=beta"

  permission_sets     = local.sso_permission_sets
  account_assignments = local.sso_account_assignments

  providers = {
    aws = aws.euc1
  }
}