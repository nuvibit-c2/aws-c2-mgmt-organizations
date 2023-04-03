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

  resource_tags = {
    "AccountType" = "Core Org Management"
    "ManagedBy"   = "Terraform Pipeline - ${local.management_account_name}"
  }

  active_org_accounts = [
    for a in data.aws_organizations_resource_tags.account : a.resource_id
    if a.resource_id == data.aws_caller_identity.current.account_id || try(a.tags.recycled == "false", false)
  ]
  org_accounts_prod    = length([for a in data.aws_organizations_resource_tags.account : a.resource_id if try(a.tags.environment == "prod", false)])
  org_accounts_nonprod = length([for a in data.aws_organizations_resource_tags.account : a.resource_id if try(a.tags.environment == "nonprod", true)])

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
# ¦ ORG MANAGEMENT ACCOUNT & PIPELINE
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

# ---------------------------------------------------------------------------------------------------------------------
# ¦ IAM IDENTITY CENTER - SSO
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