# ---------------------------------------------------------------------------------------------------------------------
# ¦ LOCALS
# ---------------------------------------------------------------------------------------------------------------------
locals {
  # global sso permissions for all accounts
  global_sso_permissions = {
    admin_users = [
      "stefano.franco@nuvibit.com"
    ]
    admin_groups   = []
    billing_users  = []
    billing_groups = []
    support_users  = []
    support_groups = []
  }

  # permissions sets which can be referenced for account assignments
  sso_permission_sets = [
    {
      name : "AdministratorAccess"
      description : "This permission set grants administrator access"
      session_duration : 2
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
      name : "Billing+ViewOnlyAccess"
      description : "This permission set grants billing and read-only access"
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
      name : "SupportUser+ReadOnlyAccess"
      description : "This permission set grants support and read-only access"
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

  # account assignments can be done for individual accounts or an account map can be used for dynamic assigments
  sso_account_assignments = [
    for account in local.organization_accounts_enriched :
    {
      account_name = account.account_name
      account_id   = account.account_id
      permissions = [
        {
          permission_set_name : "AdministratorAccess"
          # combine users with global sso permissions and users with sso permissions from account map
          users : concat(local.global_sso_permissions.admin_users, account.sso_permissions.admin_users)
          groups : concat(local.global_sso_permissions.admin_groups, account.sso_permissions.admin_groups)
          # alternatively groups names can also be dynamically generated
          # groups : ["sg-aws-admins-${account.account_id}"]
        },
        {
          permission_set_name : "Billing+ViewOnlyAccess"
          # combine users with global sso permissions and users with sso permissions from account map
          users : concat(local.global_sso_permissions.billing_users, account.sso_permissions.billing_users)
          groups : concat(local.global_sso_permissions.billing_groups, account.sso_permissions.billing_groups)
          # alternatively groups names can also be dynamically generated
          # groups : ["sg-aws-billing-${account.account_id}"]
        },
        {
          permission_set_name : "SupportUser+ReadOnlyAccess"
          # combine users with global sso permissions and users with sso permissions from account map
          users : concat(local.global_sso_permissions.support_users, account.sso_permissions.support_users)
          groups : concat(local.global_sso_permissions.support_groups, account.sso_permissions.support_groups)
          # alternatively groups names can also be dynamically generated
          # groups : ["sg-aws-support-${account.account_id}"]
        }
      ]
    }
    # only add sso permissions if account is not suspended
    if account.ou_path != "/root/suspended"
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