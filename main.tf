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
  required_version = ">= 1.2.0"

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

data "aws_ssoadmin_instances" "sso" {}
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
  foundation_settings      = module.foundation_settings.parameters
  management_account_name  = "aws-${local.env}-org-mgmt"
  tf_version               = "1.2.9"
  github_template          = "template-terraform-aws-workspace"
  management_account_email = "accounts+${local.management_account_name}@nuvibit.com"
  # core_logging_account_id  = try(local.foundation_settings["core_logging"]["account_id"], local.this_account) #workaround for provider

  resource_tags = {
    "accountClass" = "Core Organizations Management"
    "iacPipeline"  = local.management_account_name
  }

  this_account_id = data.aws_caller_identity.current.account_id

  ou_tenant_map = {
    nuvibit = "org"
  }

  token_name = "GH_SA_TOKEN"

  org_mgmt_parameters = {
    org_mgmt = {
      main_region                 = data.aws_region.current.name
      root_id                     = module.main_config.organization_root_id
      org_id                      = data.aws_organizations_organization.current.id
      branding_ou_id              = module.main_config.branding_ou_id
      tenant_ou_ids               = jsonencode(module.main_config.tenant_ou_ids)
      account_id                  = local.this_account_id
      account_name                = local.management_account_name
      context_reader_role_name    = "foundation-read-account-context-role"
      parameters_writer_role_name = "foundation-write-parameter-role"
      parameters_reader_role_name = "foundation-read-parameter-role"
      account_access_role         = "OrganizationAccountAccessRole"
      env                         = local.env
    }
    account_baseline = {
      workload_provisioning_user_name = "tf_workload_provisioning"
      provisioning_role_name          = "FoundationBaselineProvisioningRole"
      auto_remediation_role_name      = "foundation-auto-remediation-role"
      aws_config_role_name            = "FoundationAwsConfigRole"
      baseline_repo                   = "aws-${local.env}-account-baseline"
      baseline_source_repo            = "app.terraform.io/nuvibit/account-baseline/aws"
      baseline_version                = "0.6.1"
      max_accounts_per_workspace      = local.max_accounts_per_workspace
    }
    core_vending = {
      gh_token                = local.token_name
      tf_version              = local.tf_version
      github_template         = local.github_template
      account_context_version = "1.1.0"
      core_parameter_version  = "1.0.0"
      account_id              = local.this_account_id
    }
  }

  org_mgmt_settings = try(merge(local.org_mgmt_parameters, { core_security = local.foundation_settings["core_security"] }), local.org_mgmt_parameters)

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

  sso_identity_store_id         = tolist(data.aws_ssoadmin_instances.sso.identity_store_ids)[0]
  sso_identity_store_arn        = tolist(data.aws_ssoadmin_instances.sso.arns)[0]
  sso_aws_managed_job_functions = ["AdministratorAccess", "Billing", "SupportUser"]
  sso_admin_users = [
    "stefano.franco@nuvibit.com",
    "jonas.saegesser@nuvibit.com",
    "andreas.moor@nuvibit.com",
    "roman.plessl@nuvibit.com",
    "christoph.siegrist@nuvibit.com",
    "michael.ullrich@nuvibit.com",
  ]
  sso_admin_groups     = []
  sso_billing_groups   = []
  sso_supporter_groups = []
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ ORGANIZATION
# ---------------------------------------------------------------------------------------------------------------------
module "main_config" {
  source  = "app.terraform.io/nuvibit/org-mgmt/aws"
  version = "1.5.2"

  ou_tenant_map  = local.ou_tenant_map
  org_parameters = local.org_mgmt_settings
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
  source  = "app.terraform.io/nuvibit/core-parameters/aws//modules/reader"
  version = "1.0.0"

  providers = {
    aws               = aws.euc1
    aws.ssm_ps_reader = aws.euc1
  }
}

module "org_mgmt_parameters" {
  source  = "app.terraform.io/nuvibit/core-parameters/aws"
  version = "1.0.0"

  parameters           = local.org_mgmt_parameters
  parameters_overwrite = true

  providers = {
    aws               = aws.euc1
    aws.ssm_ps_writer = aws.euc1
  }
}

module "parameter_roles" {
  source  = "app.terraform.io/nuvibit/core-parameters/aws//modules/iam-roles"
  version = "1.0.0"

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
# ¦ IDENTITY CENTER
# ---------------------------------------------------------------------------------------------------------------------
module "sso_permission_sets" {
  source = "github.com/nuvibit/terraform-aws-sso-gen2//modules/permission-sets?ref=feat-init2"

  sso_identity_store_arn           = local.sso_identity_store_arn
  aws_managed_job_functions        = local.sso_aws_managed_job_functions
  custom_job_functions_org_billing = true # additionally create custom billing permission-set

  providers = {
    aws = aws.euc1
  }
}

module "sso_org_admins" {
  source = "github.com/nuvibit/terraform-aws-sso-gen2?ref=feat-init2"

  for_each = toset(local.active_org_accounts)

  sso_account_id                  = each.key
  sso_identity_store_id           = local.sso_identity_store_id
  sso_admin_user_list             = local.sso_admin_users
  sso_admin_group_list            = local.sso_admin_groups
  sso_billing_group_list          = local.sso_billing_groups
  sso_supporter_group_list        = local.sso_supporter_groups
  sso_permission_sets_map         = module.sso_permission_sets.sso_permission_sets_map
  sso_billing_permission_set_name = "OrgBilling" # org admins get a custom billing permission set

  providers = {
    aws = aws.euc1
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ ACCOUNT VENDING
# ---------------------------------------------------------------------------------------------------------------------
module "account_vendor" {
  source  = "app.terraform.io/nuvibit/account-vendor/aws"
  version = "1.4.0"

  resource_name_suffix          = local.org_mgmt_settings["org_mgmt"].env
  account_role                  = local.org_mgmt_settings["org_mgmt"].account_access_role
  baseline_managed_by_terraform = true
  cloud_management_role_arn     = "arn:aws:iam::${local.this_account_id}:role/cloud-management"
  org_mgmt_account_id           = local.this_account_id

  providers = {
    aws      = aws.euc1
    aws.use1 = aws.use1
  }
}