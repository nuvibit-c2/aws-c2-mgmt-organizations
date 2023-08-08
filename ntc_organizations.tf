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

  # template module outputs service control policies (SCP)
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
    # (optional) log cloudtrail to cloudwatch for real time analysis
    cloud_watch_logs_enable = false
    # cloud_watch_logs_existing   = false
    # cloud_watch_logs_group_name = "organization-trail-logs"
    # cloud_watch_logs_role_name  = "organization-trail-logs"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ NTC ORGANIZATIONS
# ---------------------------------------------------------------------------------------------------------------------
module "organizations" {
  source = "github.com/nuvibit-terraform-collection/terraform-aws-ntc-organizations?ref=1.0.0"

  service_access_principals = local.service_access_principals
  organizational_unit_paths = local.organizational_unit_paths
  service_control_policies  = local.service_control_policies
  organization_trail        = local.organization_trail

  providers = {
    aws = aws.euc1
  }
}