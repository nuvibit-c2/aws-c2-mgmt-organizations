# ---------------------------------------------------------------------------------------------------------------------
# ¦ PROVIDER
# ---------------------------------------------------------------------------------------------------------------------
provider "aws" {
  region = "eu-central-1"
}

provider "aws" {
  region = "eu-central-1"
  alias  = "euc1"
}

provider "aws" {
  alias  = "euw1"
  region = "eu-west-1"
}

provider "aws" {
  alias  = "use1"
  region = "us-east-1"
}

provider "azuread" {
  alias = "sso"
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ REQUIREMENTS
# ---------------------------------------------------------------------------------------------------------------------
terraform {
  required_version = ">= 0.15.0"

  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = ">3.15"
      configuration_aliases = [aws.use1]
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ DATA
# ---------------------------------------------------------------------------------------------------------------------
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_organizations_organization" "current" {}
data "aws_organizations_organizational_units" "ou" {
  parent_id = data.aws_organizations_organization.current.roots[0].id
}
data "aws_organizations_resource_tags" "account" {
  for_each = { for a in data.aws_organizations_organization.current.accounts : a.id => a if(
    a.status == "ACTIVE"
  ) }

  resource_id = each.key
}
# ---------------------------------------------------------------------------------------------------------------------
# ¦ LOCALS
# ---------------------------------------------------------------------------------------------------------------------
locals {
  resource_tags = {
    "accountClass" = "Core Organizations Management"
    "iacPipeline"  = "aws-c2-org-mgmt"
  }

  suffix   = title(var.resource_name_suffix)
  suffix_k = local.suffix == "" ? "" : format("-%s", local.suffix) // Kebap
  suffix_s = local.suffix == "" ? "" : format("_%s", local.suffix) // Snake

  this_account = data.aws_caller_identity.current.account_id

  ou_tenant_map = {
    customer1 = "org"
  }

  token_name = "GH_SA_TOKEN"

  org_mgmt_settings = {
    org_mgmt = {
      main_region               = data.aws_region.current.name
      root_id                   = module.master_config.organization_root_id
      org_id                    = data.aws_organizations_organization.current.id
      branding_ou_id            = module.master_config.branding_ou_id
      tenant_ou_ids             = jsonencode(module.master_config.tenant_ou_ids)
      account_id                = data.aws_caller_identity.current.account_id
      env                       = "c2"
      read_context_role_name    = "foundation-read-account-context-role"
      write_parameter_role_name = "foundation-write-parameter-role"
      account_access_role       = "OrganizationAccountAccessRole"
    }
    account_baseline = {
      workload_provisioning_user_name = "tf_workload_provisioning"
      provisioning_role_name          = "FoundationBaselineProvisioningRole"
      auto_remediation_role_name      = "foundation-auto-remediation-role"
      aws_config_role_name            = "FoundationAwsConfigRole"
    }
    core_vending = {
      gh_token                = local.token_name
      account_context_version = "main"
      baseline_version        = "main"
      account_id              = local.this_account
    }
  }

  vending_settings = {
    baseline_repo      = "https://${local.token_name}:<token>@github.com/nuvibit/aws-${local.org_mgmt_settings["org_mgmt"].env}-baseline.git"
    account_role       = local.org_mgmt_settings["org_mgmt"].account_access_role
    baseline_version   = "main"
    org_mgmt_id        = local.this_account
    vending_account_id = local.this_account
    cloud_management   = "arn:aws:iam::${local.this_account}:role/cloud-management"
    token_name         = local.token_name
    git_token          = var.git_token
  }

  vending_context = {

  }
  foundation_settings = module.account_context.foundation_settings

  foundation_settings_security = {
    org_mgmt = {
      security_provisioning_role = module.foundation_security_provisioner.org_mgmt_provisioner_role_arn
    }
  }

  active_org_accounts = [for a in data.aws_organizations_resource_tags.account : a.resource_id if(
    a.resource_id == data.aws_caller_identity.current.account_id || try(a.tags.recycled == "false", false)
  )]
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ FOUNDATION CONTEXT
# ---------------------------------------------------------------------------------------------------------------------
module "account_context" {
  source = "github.com/nuvibit/terraform-aws-account-context.git?ref=main"

  account_id = local.this_account
  providers = {
    aws.org-mgmt = aws
  }
}

module "foundation_settings_security" {
  source = "github.com/nuvibit/terraform-aws-org-mgmt.git//modules/ssm-parameters?ref=main"

  parameters          = local.foundation_settings_security
  resource_tags       = local.resource_tags
  parameter_overwrite = true
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ FOUNDATION SECURITY PROVISIONER
# ---------------------------------------------------------------------------------------------------------------------
module "foundation_security_provisioner" {
  source = "github.com/nuvibit/terraform-aws-foundation-security.git//modules/iam-roles-provisioner?ref=main"

  org_mgmt_account_id      = local.org_mgmt_settings["org_mgmt"]["account_id"]
  core_security_account_id = try(local.foundation_settings["core_security"]["account_id"], local.this_account)
  provisioner_role_name    = try(local.foundation_settings["core_security"]["spoke_provisioning_role_name"], "placeholder")
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦  ORGANIZATION
# ---------------------------------------------------------------------------------------------------------------------
module "master_config" {
  source = "github.com/nuvibit/terraform-aws-org-mgmt.git?ref=add-cloudtrail"

  ou_tenant_map      = local.ou_tenant_map
  vending_account_id = try(module.account_context.foundation_settings["core_vending"].account_id, local.this_account)
  statemachine_arn   = module.account_vendor.state_machine_arn

  org_parameters = local.org_mgmt_settings
  resource_tags  = local.resource_tags

  providers = {
    aws.use1 = aws.use1
    aws      = aws
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ ORG MGMT - ORGANIZATION CLOUDTRAIL
# ---------------------------------------------------------------------------------------------------------------------
module "org_cloudtrail" {
  source = "github.com/nuvibit/terraform-aws-foundation-security.git//modules/org-cloudtrail?ref=move-org-mgmt-configs"

  org_mgmt_account_id                         = local.org_mgmt_account_id
  core_security_account_id                    = var.core_logging_account_id
  core_monitoring_cloudtrail_cw_logs_dest_arn = var.core_monitoring_cloudtrail_cw_logs_dest_arn
  core_logging_account_id                     = var.core_logging_account_id
  s3_days_to_glacier                          = var.s3_days_to_glacier
  s3_days_to_expiration                       = var.s3_days_to_expiration
  core_logging_bucket_access_s3_id            = var.core_logging_bucket_access_s3_id

  resource_tags = var.resource_tags
  providers = {
    aws              = aws
    aws.core_logging = aws.core_logging
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ SINGLE SIGN ON
# ---------------------------------------------------------------------------------------------------------------------
module "aws-c2" {
  source = "github.com/nuvibit/terraform-aws-sso.git//modules/azuread-org-sso"

  saml_cert_manual_rotation = 0
  admin_mail                = "stefano.franco@nuvibit.com"
  TF_VAR_ARM_CLIENT_SECRET  = var.TF_VAR_ARM_CLIENT_SECRET
  aws_sso_org               = "aws-c2"
  aws_sso_sign_in_url       = "https://d-996719544f.awsapps.com/start"
  aws_sso_acs_url           = "https://eu-central-1.signin.aws.amazon.com/platform/saml/acs/85f2a8f3-9efd-4a5d-82d4-536a359a8c35"
  aws_sso_issuer_url        = "https://eu-central-1.signin.aws.amazon.com/platform/saml/d-996719544f"
  aws_sso_manual_config     = true
  aws_sso_session_duration  = 10
  aws_sso_users = [
    {
      "email" : "stefano.franco@nuvibit.com"
      "roles" : ["AdministratorAccess", "ViewOnlyAccess"]
      "accounts" : local.active_org_accounts
    },
    {
      "email" : "jonas.saegesser@nuvibit.com"
      "roles" : ["AdministratorAccess", "ViewOnlyAccess"]
      "accounts" : local.active_org_accounts
    },
    {
      "email" : "andreas.moor@nuvibit.com"
      "roles" : ["AdministratorAccess", "ViewOnlyAccess"]
      "accounts" : local.active_org_accounts
    },
    {
      "email" : "roman.plessl@nuvibit.com"
      "roles" : ["AdministratorAccess", "ViewOnlyAccess"]
      "accounts" : local.active_org_accounts
    },
    {
      "email" : "christoph.siegrist@nuvibit.com"
      "roles" : ["AdministratorAccess", "ViewOnlyAccess"]
      "accounts" : local.active_org_accounts
    },
    {
      "email" : "michael.ullrich@nuvibit.com"
      "roles" : ["AdministratorAccess", "ViewOnlyAccess"]
      "accounts" : local.active_org_accounts
    }
  ]

  providers = {
    azuread              = azuread.sso
    aws.org_mgmt_account = aws.euc1
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ Account Vending
# ---------------------------------------------------------------------------------------------------------------------
module "account_vendor" {
  source = "github.com/nuvibit/terraform-aws-account-vendor.git?ref=v1.0.0"

  resource_name_suffix = local.org_mgmt_settings["org_mgmt"].env
  vending_settings     = local.vending_settings

  providers = {
    aws = aws
  }
}