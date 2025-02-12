# ---------------------------------------------------------------------------------------------------------------------
# ¦ NTC ORGANIZATIONS
# ---------------------------------------------------------------------------------------------------------------------
module "ntc_organizations" {
  source = "github.com/nuvibit-terraform-collection/terraform-aws-ntc-organizations?ref=1.3.1"

  # enable sharing resources within your organization
  enable_ram_sharing_in_organization = true

  # list of services which should be enabled in Organizations
  # https://docs.aws.amazon.com/organizations/latest/userguide/orgs_integrate_services_list.html
  # the following services will be enabled by default, but can be overwritten
  service_access_principals = [
    "account.amazonaws.com",
    "servicequotas.amazonaws.com",
    "cloudtrail.amazonaws.com",
    "securityhub.amazonaws.com",
    "config.amazonaws.com",
    "config-multiaccountsetup.amazonaws.com",
    "guardduty.amazonaws.com",
    "malware-protection.guardduty.amazonaws.com",
    "inspector2.amazonaws.com",
    "access-analyzer.amazonaws.com",
    "sso.amazonaws.com",
    "ipam.amazonaws.com",
    "iam.amazonaws.com",
  ]

  # list of nested (up to 5 levels) organizational units
  organizational_unit_paths = [
    "/root/infrastructure",
    "/root/security",
    "/root/sandbox",
    "/root/suspended",
    "/root/decommission",
    "/root/workloads",
    "/root/workloads/prod",
    "/root/workloads/dev",
    "/root/workloads/test"
  ]

  # list of SCPs which should be attached to multiple organizational units and/or accounts
  service_control_policies = [
    # {
    #   policy_name        = "scp_deny_all_outside_eu_regions",
    #   target_ou_paths    = ["/root/workloads"]
    #   target_account_ids = []
    #   policy_json        = "INSERT_SCP_JSON"
    # }
    module.ntc_guardrail_templates.service_control_policies["scp_root_ou"],
    module.ntc_guardrail_templates.service_control_policies["scp_suspended_ou"],
    # module.ntc_guardrail_templates.service_control_policies["scp_workloads_ou"],
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

  # create an organization reader IAM role which can be assumed by specified principals
  # optional for 'ntc-security-tooling' and required for 'ntc-cross-account-orchestration'
  organization_reader = {
    enabled = true
    # list of IAM principals which can assume the org_reader role (e.g. account ids)
    allowed_principals = [
      local.ntc_parameters["mgmt-account-factory"]["core_accounts"]["aws-c2-security"],
      local.ntc_parameters["mgmt-account-factory"]["core_accounts"]["aws-c2-connectivity"]
    ]
    iam_role_name   = "ntc-org-account-reader"
    iam_role_path   = "/"
    iam_policy_name = "ntc-org-account-reader-policy"
  }

  providers = {
    aws = aws.euc1
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ NTC ORGANIZATIONS - SERVICE QUOTAS
# ---------------------------------------------------------------------------------------------------------------------
module "ntc_organization_quotas" {
  source = "github.com/nuvibit-terraform-collection/terraform-aws-ntc-organizations//modules/service-quotas?ref=1.3.0"

  # increase service quotas for the org management account
  increase_aws_service_quotas = {
    # organizations_maximum_number_of_accounts = 100
  }

  # service quota templates will apply service quotas to all new organization accounts (existing accounts won't be updated)
  aws_service_quota_templates = [
    # {
    #   regions      = ["eu-central-1"]
    #   quota_name   = "Services per namespace"
    #   service_code = "ecs"
    #   new_value    = 120
    # }
  ]

  providers = {
    aws.us_east_1 = aws.use1 # organization service quotas and service quota templates must be created in us-east-1
  }
}
