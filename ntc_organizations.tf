# NOTE: you can import and manage an existing AWS Organization using the following import block:

# import {
#   to = module.ntc_organizations.aws_organizations_organization.ntc_org
#   id = "o-xxxxxxxx" # NOTE: replace with your organization id
# }

# ---------------------------------------------------------------------------------------------------------------------
# ¦ NTC ORGANIZATIONS
# ---------------------------------------------------------------------------------------------------------------------
module "ntc_organizations" {
  source = "github.com/nuvibit-terraform-collection/terraform-aws-ntc-organizations?ref=1.6.0"

  # enable sharing resources within your organization
  enable_ram_sharing_in_organization = true

  # list of services which should be enabled in Organizations
  # https://docs.aws.amazon.com/organizations/latest/userguide/orgs_integrate_services_list.html
  # the following services will be enabled by default, but can be overwritten
  service_access_principals = [
    "iam.${local.current_partition_dns_suffix}",
    "account.${local.current_partition_dns_suffix}",
    "servicequotas.${local.current_partition_dns_suffix}",
    "cloudtrail.${local.current_partition_dns_suffix}",
    "securityhub.${local.current_partition_dns_suffix}",
    "config.${local.current_partition_dns_suffix}",
    "config-multiaccountsetup.${local.current_partition_dns_suffix}",
    "guardduty.${local.current_partition_dns_suffix}",
    "inspector2.${local.current_partition_dns_suffix}",
    "macie.${local.current_partition_dns_suffix}",
    "malware-protection.guardduty.${local.current_partition_dns_suffix}",
    "access-analyzer.${local.current_partition_dns_suffix}",
    "sso.${local.current_partition_dns_suffix}",
    "ipam.${local.current_partition_dns_suffix}",
  ]

  # list of nested (up to 5 levels) organizational units
  # make sure that there is a parent OU when creating child OUs (e.g. "/root/workloads" must exist when creating "/root/workloads/prod")
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
    module.ntc_guardrail_templates.service_control_policies["scp_workloads_ou"],
    # altenatively, you can enable stricter guardrails with C5 compliance or only whitelisted services
    # module.ntc_guardrail_templates.service_control_policies["scp_workloads_ou_c5_compliance"],
    # module.ntc_guardrail_templates.service_control_policies["scp_workloads_ou_whitelisted_services"],
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

  # NOTE: 'organization_trail' requires that the log-archive account is already provisioned - comment out for initial deployment
  # s3 log archive bucket must be provisioned before creating the organization trail
  organization_trail = {
    kms_key_arn    = local.ntc_parameters["log-archive"]["log_bucket_kms_key_arns"]["org_cloudtrail"]
    s3_bucket_name = local.ntc_parameters["log-archive"]["log_bucket_ids"]["org_cloudtrail"]
    # (optional) log cloudtrail to cloudwatch for real time analysis
    cloud_watch_logs_enable = false
    # cloud_watch_logs_existing   = false
    # cloud_watch_logs_group_name = "organization-trail-logs"
    # cloud_watch_logs_role_name  = "organization-trail-logs"
  }

  # NOTE: 'organization_reader' requires that accounts for specified principals are already provisioned - comment out for initial deployment (if this feature is needed)
  # (optional) create an organization reader IAM role which can be assumed by specified principals
  # can be used for 'ntc-security-tooling' to enrich findings with alternate contact information (e.g. security contact information)
  organization_reader = {
    enabled = true
    # list of IAM principals which can assume the org_reader role (e.g. account ids)
    allowed_principals = [
      local.ntc_parameters["mgmt-account-factory"]["core_accounts"]["aws-c2-security"] # NOTE: replace account name for your deployment
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
# NOTE: organization template quotas are not supported in China Regions or opt-in Regions (e.g. Zurich)
# alternatively you can use the ntc-account-factory account lifecycle automation to increase service quotas in member accounts
module "ntc_organization_quotas" {
  source = "github.com/nuvibit-terraform-collection/terraform-aws-ntc-organizations//modules/service-quotas?ref=1.5.0"

  # increase service quotas for the org management account
  increase_aws_service_quotas = {
    organizations_maximum_number_of_accounts = 20
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
