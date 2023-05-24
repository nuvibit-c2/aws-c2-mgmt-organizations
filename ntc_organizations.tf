# ---------------------------------------------------------------------------------------------------------------------
# ¦ LOCALS
# ---------------------------------------------------------------------------------------------------------------------
locals {
  # list of services which should be enabled in Organizations
  # the following services will be enabled by default, but can be overwritten
  service_access_principals = [
    "account.amazonaws.com",
    "cloudtrail.amazonaws.com",
    "securityhub.amazonaws.com",
    "config.amazonaws.com",
    "config-multiaccountsetup.amazonaws.com",
    "guardduty.amazonaws.com",
    "malware-protection.guardduty.amazonaws.com",
    "sso.amazonaws.com",
    "ipam.amazonaws.com",
    "ram.amazonaws.com"
  ]

  # list of nested (up to 5 levels) organizational units
  organizational_unit_paths = [
    "/root/infrastructure",
    "/root/security",
    "/root/sandbox",
    "/root/suspended",
    "/root/workloads",
    "/root/workloads/prod",
    "/root/workloads/dev",
    "/root/workloads/test"
  ]

  # service control policies can either be defined by customer or consumed via template module
  # https://github.com/nuvibit-terraform-collection/terraform-aws-ntc-scp-templates
  service_control_policy_templates = [
    {
      policy_name     = "scp_root_ou"
      target_ou_paths = ["/root"]
      template_names  = ["deny_leaving_organizations", "deny_actions_as_root"]
    },
    {
      policy_name            = "scp_suspended_ou"
      target_ou_paths        = ["/root/suspended"]
      template_names         = ["deny_all"]
      exclude_principal_arns = ["arn:aws:iam::*:role/OrganizationAccountAccessRole"]
    },
    {
      policy_name            = "scp_workloads_ou"
      target_ou_paths        = ["/root/workloads"]
      template_names         = ["deny_outside_allowed_regions"]
      allowed_regions        = ["eu-central-1", "eu-central-2"]
      exclude_principal_arns = ["arn:aws:iam::*:role/OrganizationAccountAccessRole"]
    }
  ]
  service_control_policy_templates_outputs = module.service_control_policy_templates.service_control_policies

  # list of SCPs which should be attached to multiple organizational units and/or accounts
  service_control_policies = [
    # {
    #   policy_name        = "scp_deny_all_outside_eu_regions",
    #   target_ou_paths    = ["/root/workloads"]
    #   target_account_ids = []
    #   policy_json        = "INSERT_SCP_JSON"
    # }
    local.service_control_policy_templates_outputs["scp_root_ou"],
    local.service_control_policy_templates_outputs["scp_suspended_ou"],
    local.service_control_policy_templates_outputs["scp_workloads_ou"],
  ]

  # s3 log archive bucket must be provisioned before creating the organization trail
  organization_trail = {
    kms_key_arn    = try(local.ntc_parameters["log-archive"]["log_bucket_kms_key_arns"]["org_cloudtrail"], null)
    s3_bucket_name = try(local.ntc_parameters["log-archive"]["log_bucket_ids"]["org_cloudtrail"], null)
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ NTC SERVICE CONTROL POLICY TEMPLATES
# ---------------------------------------------------------------------------------------------------------------------
module "service_control_policy_templates" {
  source = "github.com/nuvibit-terraform-collection/terraform-aws-ntc-scp-templates?ref=beta"

  service_control_policy_templates = local.service_control_policy_templates
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ NTC ORGANIZATION
# ---------------------------------------------------------------------------------------------------------------------
module "organization" {
  source = "github.com/nuvibit-terraform-collection/terraform-aws-ntc-organizations?ref=beta"

  service_access_principals = local.service_access_principals
  organizational_unit_paths = local.organizational_unit_paths
  service_control_policies  = local.service_control_policies
  organization_trail        = local.organization_trail

  providers = {
    aws = aws.euc1
  }
}