# ---------------------------------------------------------------------------------------------------------------------
# ¦ PROVIDER
# ---------------------------------------------------------------------------------------------------------------------
provider "aws" {
  region = "eu-central-1"
  default_tags {
    tags = local.resource_tags
  }
}

provider "aws" {
  alias  = "euc1"
  region = "eu-central-1"
  default_tags {
    tags = local.resource_tags
  }
}

provider "aws" {
  alias  = "use1"
  region = "us-east-1"
  default_tags {
    tags = local.resource_tags
  }
}

# provider "aws" {
#   alias                  = "euc2"
#   region                 = "eu-central-2"
#   skip_region_validation = true
# }

# ---------------------------------------------------------------------------------------------------------------------
# ¦ REQUIREMENTS
# ---------------------------------------------------------------------------------------------------------------------
terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 4.10, != 4.34"
      configuration_aliases = []
    }
    tfe = {
      source  = "hashicorp/tfe"
      version = "~> 0.31"
    }
    github = {
      source  = "integrations/github"
      version = "~> 5.0"
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ DATA
# ---------------------------------------------------------------------------------------------------------------------
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

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
  env                      = "c2"
  organization             = "nuvibit"
  management_account_name  = "aws-${local.env}-org-mgmt"
  management_account_email = "accounts+${local.management_account_name}@nuvibit.com"
  tf_version               = "1.3.6"
  github_template          = "template-terraform-aws-workspace"
  # core_logging_account_id  = try(local.foundation_settings["core_logging"]["account_id"], local.this_account) #workaround for provider

  this_account_id = data.aws_caller_identity.current.account_id
  resource_tags = {
    "accountClass" = "Core Organizations Management"
    "iacPipeline"  = local.management_account_name
  }

  ou_tenant_map = {
    nuvibit = "org"
  }

  active_org_accounts = [
    for a in data.aws_organizations_resource_tags.account : a.resource_id
    if a.resource_id == data.aws_caller_identity.current.account_id || try(a.tags.recycled == "false", false)
  ]
  org_accounts_prod    = length([for a in data.aws_organizations_resource_tags.account : a.resource_id if try(a.tags.environment == "prod", false)])
  org_accounts_nonprod = length([for a in data.aws_organizations_resource_tags.account : a.resource_id if try(a.tags.environment == "nonprod", true)])

  max_accounts_per_workspace = 20
  account_baseline_workspaces = merge({
    "p1" = { "create_repo" = true }
    "n1" = { "create_repo" = false }
    },
    merge(
      {
        # generate additional workspaces once max_accounts_per_workspace limit is reached with a lead of 2 accounts
        for i in range(floor(ceil((try(local.org_accounts_prod, 0) + 2) / local.max_accounts_per_workspace) - 1)) :
        "p${i + 2}" => { "create_repo" = false }
      },
      {
        # generate additional workspaces once max_accounts_per_workspace limit is reached with a lead of 2 accounts
        for i in range(floor(ceil((try(local.org_accounts_nonprod, 0) + 2) / local.max_accounts_per_workspace) - 1)) :
        "n${i + 2}" => { "create_repo" = false }
      }
    )
  )

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
            "jonas.saegesser@nuvibit.com",
            "andreas.moor@nuvibit.com",
            "roman.plessl@nuvibit.com",
            "michael.ullrich@nuvibit.com",
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
# ¦ ORGANIZATION
# ---------------------------------------------------------------------------------------------------------------------
module "main_config" {
  source  = "app.terraform.io/nuvibit/org-mgmt/aws"
  version = "1.5.2"

  ou_tenant_map  = local.ou_tenant_map
  org_parameters = local.org_mgmt_parameters
  resource_tags  = local.resource_tags

  providers = {
    aws      = aws.euc1
    aws.use1 = aws.use1
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ FOUNDATION PARAMETERS
# ---------------------------------------------------------------------------------------------------------------------
module "foundation_settings" {
  source  = "nuvibit/core-parameters/aws//modules/reader"
  version = "1.0.1"

  providers = {
    aws               = aws.euc1
    aws.ssm_ps_reader = aws.euc1
  }
}

module "org_mgmt_parameters" {
  source  = "nuvibit/core-parameters/aws"
  version = "1.0.1"

  parameters           = local.org_mgmt_parameters
  parameters_overwrite = true

  providers = {
    aws               = aws.euc1
    aws.ssm_ps_writer = aws.euc1
  }
}

module "parameter_roles" {
  source  = "nuvibit/core-parameters/aws//modules/iam-roles"
  version = "1.0.1"

  org_id                      = local.org_mgmt_parameters["org_mgmt"]["org_id"]
  parameters_writer_role_name = local.org_mgmt_parameters["org_mgmt"]["parameters_writer_role_name"]
  parameters_reader_role_name = local.org_mgmt_parameters["org_mgmt"]["parameters_reader_role_name"]

  providers = {
    aws = aws.euc1
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ ORG MANAGEMENT ACCOUNT & PIPELINES
# ---------------------------------------------------------------------------------------------------------------------
# Import org-mgmt account!
resource "aws_organizations_account" "org_management" {
  name      = local.management_account_name
  email     = local.management_account_email
  parent_id = null
  tags = {
    account_email = local.management_account_email
    account_name  = local.management_account_name
  }
}

module "org_mgmt_pipline" {
  source  = "app.terraform.io/nuvibit/org-mgmt-piplines/aws"
  version = "1.2.2"

  workspace_name  = local.management_account_name
  organization    = local.organization
  env             = local.env
  tf_version      = local.tf_version
  github_template = local.github_template

  providers = {
    aws    = aws.euc1
    tfe    = tfe
    github = github
  }
}

module "account_lifecycle_pipline" {
  source  = "app.terraform.io/nuvibit/org-mgmt-piplines/aws"
  version = "1.2.2"

  workspace_name         = "aws-${local.env}-account-lifecycle"
  organization           = local.organization
  env                    = local.env
  tf_version             = local.tf_version
  provisioning_user_name = "account_provisioner"
  github_template        = local.github_template

  providers = {
    aws    = aws.euc1
    tfe    = tfe
    github = github
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# DYNAMIC ACCOUNT BASELINE PIPELINES
# ---------------------------------------------------------------------------------------------------------------------
module "account_baseline_pipline" {
  source   = "app.terraform.io/nuvibit/org-mgmt-piplines/aws"
  version  = "1.2.2"
  for_each = local.account_baseline_workspaces

  workspace_name            = local.org_mgmt_parameters["account_baseline"].baseline_repo
  organization              = local.organization
  env                       = local.env
  tf_version                = local.tf_version
  provisioning_user_name    = "account_baseline_provisioner"
  github_template           = local.github_template
  tfc_state_read_permission = [module.account_lifecycle_pipline.tfc_workspace_id]

  tfc_working_directory     = each.key
  setup_github              = each.value.create_repo
  setup_account_config      = !each.value.create_repo
  account_baseline_workflow = true
  github_enforce_admins     = false

  providers = {
    aws    = aws.euc1
    tfe    = tfe
    github = github
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ ACCOUNT VENDING
# ---------------------------------------------------------------------------------------------------------------------
module "account_vendor" {
  source  = "app.terraform.io/nuvibit/account-vendor/aws"
  version = "1.4.0"

  resource_name_suffix          = local.org_mgmt_parameters["org_mgmt"].env
  account_role                  = local.org_mgmt_parameters["org_mgmt"].account_access_role
  baseline_managed_by_terraform = true
  vendor_cloudtrail_enabled     = true
  cloud_management_role_arn     = "arn:aws:iam::${local.this_account_id}:role/cloud-management"
  org_mgmt_account_id           = local.this_account_id

  providers = {
    aws      = aws.euc1
    aws.use1 = aws.use1
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ SSO IDENTITY CENTER
# ---------------------------------------------------------------------------------------------------------------------
module "sso_identity_center" {
  # source = "github.com/nuvibit/terraform-aws-sso?ref=feat-branch"
  source  = "app.terraform.io/nuvibit/sso/aws"
  version = "1.0.0"

  permission_sets     = local.sso_permission_sets
  account_assignments = local.sso_account_assignments

  providers = {
    aws = aws.euc1
  }
}