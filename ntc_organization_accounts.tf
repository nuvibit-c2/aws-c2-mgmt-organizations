# ---------------------------------------------------------------------------------------------------------------------
# ¦ LOCALS
# ---------------------------------------------------------------------------------------------------------------------
locals {
  # account ids and status are provided as a map by organization module
  organization_account_ids    = module.organization.organization_account_ids
  organization_account_status = module.organization.organization_account_status

  # original account map enriched with addition values e.g. account id, status
  organization_accounts_enriched = [
    for account in local.organization_accounts : merge(
      account,
      {
        account_id     = local.organization_account_ids[account.account_name]
        account_status = local.organization_account_status[account.account_name]
      }
    )
  ]

  # map of organizational accounts which can be maintaned via gitflow (manual or automated)
  organization_accounts = [
    {
      # the management account was initially created manually and should be imported into Terraform
      # terraform import 'module.organization.aws_organizations_account.ntc_account["aws-c2-management"]' 111111111111
      account_name      = "aws-c2-management"
      account_email     = "accounts+aws-c2-management@nuvibit.com"
      ou_path           = "/root"
      close_on_deletion = false
      account_tags = {
        "Owner" : "stefano.franco@nuvibit.com"
        "Function" : "Core Organization Management"
        "Description" : "This account manages the AWS Organization"
      }
      # example of static sso permission mapping
      sso_admin_groups = []
      sso_admin_users  = []
      #
      sso_billing_groups = []
      sso_billing_users  = []
      #
      sso_support_groups = []
      sso_support_users  = []
    },
    {
      account_name      = "aws-c2-connectivity"
      account_email     = "accounts+aws-c2-connectivity@nuvibit.com"
      ou_path           = "/root/infrastructure"
      close_on_deletion = false
      account_tags = {
        "Owner" : "stefano.franco@nuvibit.com"
        "Function" : "Core Connectivity"
        "Description" : "This account manages centralized connectivity"
      }
      # example of static sso permission mapping
      sso_admin_groups = []
      sso_admin_users  = []
      #
      sso_billing_groups = []
      sso_billing_users  = []
      #
      sso_support_groups = []
      sso_support_users  = []
    },
    {
      account_name      = "aws-c2-security"
      account_email     = "accounts+aws-c2-security@nuvibit.com"
      ou_path           = "/root/security"
      close_on_deletion = false
      account_tags = {
        "Owner" : "stefano.franco@nuvibit.com"
        "Function" : "Core Security"
        "Description" : "This account manages centralized security"
      }
      # example of static sso permission mapping
      sso_admin_groups = []
      sso_admin_users  = []
      #
      sso_billing_groups = []
      sso_billing_users  = []
      #
      sso_support_groups = []
      sso_support_users  = []
    },
    {
      account_name      = "aws-c2-log-archive"
      account_email     = "accounts+aws-c2-log-archive@nuvibit.com"
      ou_path           = "/root/security"
      close_on_deletion = false
      account_tags = {
        "Owner" : "stefano.franco@nuvibit.com"
        "Function" : "Core Log Archive"
        "Description" : "This account manages the centralized log archive"
      }
      # example of static sso permission mapping
      sso_admin_groups = []
      sso_admin_users  = []
      #
      sso_billing_groups = []
      sso_billing_users  = []
      #
      sso_support_groups = []
      sso_support_users  = []
    },
    {
      account_name      = "aws-c2-0001"
      account_email     = "accounts+aws-c2-0001@nuvibit.com"
      ou_path           = "/root/workloads/prod"
      close_on_deletion = true
      account_tags = {
        "Owner" : "stefano.franco@nuvibit.com"
        "Function" : "Workload"
        "Description" : "This account manages workload in prod stage"
      }
      # example of static sso permission mapping
      sso_admin_groups = []
      sso_admin_users  = []
      #
      sso_billing_groups = []
      sso_billing_users  = []
      #
      sso_support_groups = []
      sso_support_users  = []
    },
    {
      account_name      = "aws-c2-0002"
      account_email     = "accounts+aws-c2-0002@nuvibit.com"
      ou_path           = "/root/workloads/sdlc"
      close_on_deletion = true
      account_tags = {
        "Owner" : "stefano.franco@nuvibit.com"
        "Function" : "Workload"
        "Description" : "This account manages workload in dev stage"
      }
      # example of static sso permission mapping
      sso_admin_groups = []
      sso_admin_users  = []
      #
      sso_billing_groups = []
      sso_billing_users  = []
      #
      sso_support_groups = []
      sso_support_users  = []
    },
    # {
    #   account_name      = "aws-c2-1681243342"
    #   account_email     = "accounts+aws-c2-1681243342@nuvibit.com"
    #   ou_path           = "/root/sandbox"
    #   close_on_deletion = true
    #   account_tags = {
    #     "Owner" : "stefano.franco@nuvibit.com"
    #     "Function" : "Sandbox"
    #     "Description" : "This account is a sandbox test"
    #     "Recycled" : false
    #   }
    # },
  ]
}