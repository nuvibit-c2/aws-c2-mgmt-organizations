locals {
  org_mgmt_parameters = {
    org_mgmt = {
      main_region                 = data.aws_region.current.name
      org_id                      = data.aws_organizations_organization.current.id
      account_id                  = local.this_account_id
      account_name                = local.management_account_name
      context_reader_role_name    = "foundation-read-account-context-role"
      parameters_writer_role_name = "foundation-write-parameter-role"
      parameters_reader_role_name = "foundation-read-parameter-role"
      account_access_role         = "OrganizationAccountAccessRole"
      env                         = local.env
      # main_config modul needs to be provisioned first before adding these parameters
      root_id        = module.main_config.organization_root_id
      branding_ou_id = module.main_config.branding_ou_id
      tenant_ou_ids  = jsonencode(module.main_config.tenant_ou_ids)
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
      gh_token                = "GH_SA_TOKEN"
      tf_version              = local.tf_version
      github_template         = local.github_template
      account_context_version = "1.1.0"
      core_parameter_version  = "1.0.0"
      account_id              = local.this_account_id
    }
  }
}