# ---------------------------------------------------------------------------------------------------------------------
# ¦ NTC ORGANIZATIONS
# ---------------------------------------------------------------------------------------------------------------------
module "ntc_organizations" {
  # source = "github.com/nuvibit-terraform-collection/terraform-aws-ntc-organizations?ref=1.4.0"
  source = "github.com/nuvibit-terraform-collection/terraform-aws-ntc-organizations?ref=feat-org-policies"

  # enable sharing resources within your organization
  enable_ram_sharing_in_organization = true

  # list of services which should be enabled in Organizations
  # https://docs.aws.amazon.com/organizations/latest/userguide/orgs_integrate_services_list.html
  # the following services will be enabled by default, but can be overwritten
  service_access_principals = [
    "iam.amazonaws.com",
    "account.amazonaws.com",
    "servicequotas.amazonaws.com",
    "cloudtrail.amazonaws.com",
    "securityhub.amazonaws.com",
    "config.amazonaws.com",
    "config-multiaccountsetup.amazonaws.com",
    "guardduty.amazonaws.com",
    "inspector2.amazonaws.com",
    "macie.amazonaws.com",
    "malware-protection.guardduty.amazonaws.com",
    "access-analyzer.amazonaws.com",
    "sso.amazonaws.com",
    "ipam.amazonaws.com",
  ]

  # list of nested (up to 5 levels) organizational units
  organizational_unit_paths = [
    "/root/core",
    "/root/sandbox",
    "/root/suspended",
    "/root/transitional",
    "/root/workloads",
    "/root/workloads/prod",
    "/root/workloads/dev",
    "/root/workloads/test"
  ]

  # DEPRECATED: use 'organization_policies' instead
  service_control_policies = []

  # apply governance policies across organizational units (OUs) and member accounts
  # there are different types of policies like RESOURCE_CONTROL_POLICY, SERVICE_CONTROL_POLICY, AISERVICES_OPT_OUT_POLICY, BACKUP_POLICY, and TAG_POLICY 
  # https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies.html#orgs-policy-types
  organization_policies = [
    # {
    #   policy_name        = "scp_deny_all_outside_eu_regions" 
    #   policy_type        = "SERVICE_CONTROL_POLICY"
    #   target_ou_paths    = ["/root/workloads"]
    #   target_account_ids = []
    #   policy_json        = "INSERT_SCP_JSON"
    # }
    module.ntc_guardrail_templates.service_control_policies["scp_root_ou"],
    module.ntc_guardrail_templates.service_control_policies["scp_suspended_ou"],
    module.ntc_guardrail_templates.service_control_policies["scp_sandbox_ou"],
    # module.ntc_guardrail_templates.service_control_policies["scp_workloads_ou"],
    module.ntc_guardrail_templates.resource_control_policies["rcp_enforce_confused_deputy_protection"],
    module.ntc_guardrail_templates.resource_control_policies["rcp_enforce_principal_access_from_organization"],
    module.ntc_guardrail_templates.resource_control_policies["rcp_enforce_secure_transport"],
    module.ntc_guardrail_templates.resource_control_policies["rcp_enforce_s3_encryption_and_tls_version"],
  ]

  # after centralizing root access, you can delete root user credentials from member accounts
  # new accounts you create in Organizations will have no root user credentials by default
  # https://docs.aws.amazon.com/IAM/latest/UserGuide/id_root-enable-root-access.html
  centralize_root_access = {
    enabled = true
    features = [
      # You can delete and audit root credentials of member accounts. You can also allow password recovery for specific member accounts.
      "RootCredentialsManagement",
      # You can take certain root actions in member accounts like deleting misconfigured policies in Amazon SQS or Amazon S3.
      "RootSessions",
    ]
  }

  # s3 log archive bucket must be provisioned before creating the organization trail
  # organization_trail = {
  #   kms_key_arn    = try(local.ntc_parameters["log-archive"]["log_bucket_kms_key_arns"]["org_cloudtrail"], null)
  #   s3_bucket_name = try(local.ntc_parameters["log-archive"]["log_bucket_ids"]["org_cloudtrail"], null)
  #   # (optional) log cloudtrail to cloudwatch for real time analysis
  #   cloud_watch_logs_enable = false
  #   # cloud_watch_logs_existing   = false
  #   # cloud_watch_logs_group_name = "organization-trail-logs"
  #   # cloud_watch_logs_role_name  = "organization-trail-logs"
  # }

  # create an organization reader IAM role which can be assumed by specified principals
  # can be used for 'ntc-security-tooling' to enrich findings with alternate contact information (e.g. security contact information)
  organization_reader = {
    enabled = true
    # list of IAM principals which can assume the org_reader role (e.g. account ids)
    allowed_principals = [
      local.ntc_parameters["mgmt-account-factory"]["core_accounts"]["aws-c2-security"]
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
    #   regions      = ["us-east-1"]
    #   quota_name   = "Services per namespace"
    #   service_code = "ecs"
    #   new_value    = 120
    # }
  ]

  providers = {
    aws.us_east_1 = aws.use1 # organization service quotas and service quota templates must be created in us-east-1
  }
}
