# ---------------------------------------------------------------------------------------------------------------------
# ¦ NTC GUARDRAIL TEMPLATES
# ---------------------------------------------------------------------------------------------------------------------
module "ntc_guardrail_templates" {
  # source = "github.com/nuvibit-terraform-collection/terraform-aws-ntc-guardrail-templates?ref=1.1.0"
  source = "github.com/nuvibit-terraform-collection/terraform-aws-ntc-guardrail-templates?ref=feat-rcp"

  # service control policies (SCPs) can apply permission guardrails at the organization, organizational unit, or account level
  # https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_scps.html
  service_control_policy_templates = [
    {
      # this scp denys member accounts from leaving the organization and any root user actions except for centralized root privilege tasks
      policy_name     = "scp_root_ou"
      target_ou_paths = ["/root"]
      template_names  = ["deny_leaving_organizations", "deny_actions_as_root_except_centralized_root"]
    },
    {
      # this scp denys all actions for suspended accounts
      policy_name     = "scp_suspended_ou"
      target_ou_paths = ["/root/suspended", "/root/decommission"]
      template_names  = ["deny_all"]
      # template specific parameters
      exclude_principal_arns = ["arn:aws:iam::*:role/OrganizationAccountAccessRole"]
    },
    {
      # this scp denys all actions outside allowed regions except global services
      policy_name     = "scp_workloads_ou"
      target_ou_paths = ["/root/workloads"]
      template_names  = ["deny_outside_allowed_regions"]
      # template specific parameters
      allowed_regions = ["eu-central-1", "eu-central-2"]
      whitelist_for_other_regions = [
        # allowed global actions
        "a4b:*",
        "acm:*",
        "aws-marketplace-management:*",
        "aws-marketplace:*",
        "aws-portal:*",
        "budgets:*",
        "ce:*",
        "chime:*",
        "cloudfront:*",
        "config:*",
        "cur:*",
        "directconnect:*",
        "ec2:DescribeRegions",
        "ec2:DescribeTransitGateways",
        "ec2:DescribeVpnGateways",
        "fms:*",
        "globalaccelerator:*",
        "health:*",
        "iam:*",
        "importexport:*",
        "kms:*",
        "mobileanalytics:*",
        "networkmanager:*",
        "organizations:*",
        "pricing:*",
        "route53:*",
        "route53domains:*",
        "route53-recovery-cluster:*",
        "route53-recovery-control-config:*",
        "route53-recovery-readiness:*",
        "s3:GetAccountPublic*",
        "s3:ListAllMyBuckets",
        "s3:ListMultiRegionAccessPoints",
        "s3:PutAccountPublic*",
        "shield:*",
        "sts:*",
        "support:*",
        "trustedadvisor:*",
        "waf-regional:*",
        "waf:*",
        "wafv2:*",
        "wellarchitected:*"
      ]
      exclude_principal_arns = ["arn:aws:iam::*:role/OrganizationAccountAccessRole"]
    },
    {
      # this scp limits actions both inside and outside allowed regions
      policy_name     = "scp_sandbox_ou"
      policy_type     = "SERVICE_CONTROL_POLICY"
      target_ou_paths = ["/root/sandbox"]
      template_names  = ["deny_outside_allowed_regions", "deny_inside_allowed_regions"]
      # template specific parameters
      allowed_regions = ["eu-central-1", "eu-central-2", "eu-west-1", "us-east-1"]
      whitelist_for_other_regions = [
        # allowed global actions
        "a4b:*",
        "acm:*",
        "aws-marketplace-management:*",
        "aws-marketplace:*",
        "aws-portal:*",
        "budgets:*",
        "ce:*",
        "chime:*",
        "cloudfront:*",
        "config:*",
        "cur:*",
        "directconnect:*",
        "ec2:DescribeRegions",
        "ec2:DescribeTransitGateways",
        "ec2:DescribeVpnGateways",
        "fms:*",
        "globalaccelerator:*",
        "health:*",
        "iam:*",
        "importexport:*",
        "kms:*",
        "mobileanalytics:*",
        "networkmanager:*",
        "organizations:*",
        "pricing:*",
        "route53:*",
        "route53domains:*",
        "route53-recovery-cluster:*",
        "route53-recovery-control-config:*",
        "route53-recovery-readiness:*",
        "s3:GetAccountPublic*",
        "s3:ListAllMyBuckets",
        "s3:ListMultiRegionAccessPoints",
        "s3:PutAccountPublic*",
        "shield:*",
        "sts:*",
        "support:*",
        "trustedadvisor:*",
        "waf-regional:*",
        "waf:*",
        "wafv2:*",
        "wellarchitected:*"
      ]
      whitelist_for_allowed_regions = [
        # allowed global actions
        "a4b:*",
        "acm:*",
        "aws-marketplace-management:*",
        "aws-marketplace:*",
        "aws-portal:*",
        "budgets:*",
        "ce:*",
        "chime:*",
        "cloudfront:*",
        "config:*",
        "cur:*",
        "directconnect:*",
        "ec2:DescribeRegions",
        "ec2:DescribeTransitGateways",
        "ec2:DescribeVpnGateways",
        "fms:*",
        "globalaccelerator:*",
        "health:*",
        "iam:*",
        "importexport:*",
        "kms:*",
        "mobileanalytics:*",
        "networkmanager:*",
        "organizations:*",
        "pricing:*",
        "route53:*",
        "route53domains:*",
        "route53-recovery-cluster:*",
        "route53-recovery-control-config:*",
        "route53-recovery-readiness:*",
        "s3:GetAccountPublic*",
        "s3:ListAllMyBuckets",
        "s3:ListMultiRegionAccessPoints",
        "s3:PutAccountPublic*",
        "shield:*",
        "sts:*",
        "support:*",
        "trustedadvisor:*",
        "waf-regional:*",
        "waf:*",
        "wafv2:*",
        "wellarchitected:*",
        # allowed regional actions
        "lambda:*",
        "s3:*",
        "ec2:*"
      ]
      exclude_principal_arns = ["arn:aws:iam::*:role/OrganizationAccountAccessRole"]
    }
  ]

  # resource control policies (RCPs) can apply permission guardrails at the resource level
  # https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_rcps.html
  resource_control_policy_templates = [
    {
      # this rcp prevents the confused deputy problem for s3, sqs, kms, secretsmanager and sts
      policy_name     = "rcp_enforce_confused_deputy_protection"
      policy_type     = "RESOURCE_CONTROL_POLICY"
      target_ou_paths = ["/root"]
      template_names  = ["enforce_confused_deputy_protection"]
      # template specific parameters
      # WARNING: to avoid cyclic dependency do not reference 'module.ntc_organizations.org_id' directly
      # you can use ntc_paramters as a workaround to pass the org_id
      org_id = local.ntc_parameters["mgmt-organizations"]["org_id"]
      # list of service actions supported by RCPs
      # https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_rcps.html#rcp-supported-services
      enforced_service_actions = [
        "s3:*",
        "sqs:*",
        "kms:*",
        "secretsmanager:*",
        "sts:*",
      ]
      # add exception for certain resources
      exclude_resource_arns = []
    },
    {
      # this rcp prevents aws principals outside your organization to access resources
      policy_name     = "rcp_enforce_principal_access_from_organization"
      policy_type     = "RESOURCE_CONTROL_POLICY"
      target_ou_paths = ["/root"]
      template_names  = ["enforce_principal_access_from_organization"]
      # template specific parameters
      # WARNING: to avoid cyclic dependency do not reference 'module.ntc_organizations.org_id' directly
      # you can use ntc_paramters as a workaround to pass the org_id
      org_id = local.ntc_parameters["mgmt-organizations"]["org_id"]
      # list of service actions supported by RCPs
      # https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_rcps.html#rcp-supported-services
      enforced_service_actions = [
        "s3:*",
        "sqs:*",
        "kms:*",
        "secretsmanager:*",
        "sts:*",
      ]
      # add exception for certain resources
      exclude_resource_arns = []
      # add exception for certain principals outside your organization
      exclude_principal_arns = []
    },
    {
      # this rcp enforces that access to resources only occurs on encrypted connections over HTTPS
      policy_name     = "rcp_enforce_secure_transport"
      policy_type     = "RESOURCE_CONTROL_POLICY"
      target_ou_paths = ["/root"]
      template_names  = ["enforce_secure_transport"]
      # list of service actions supported by RCPs
      # https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_rcps.html#rcp-supported-services
      enforced_service_actions = [
        "s3:*",
        "sqs:*",
        "kms:*",
        "secretsmanager:*",
        "sts:*",
      ]
      # add exception for certain resources
      exclude_resource_arns = []
    },
    {
      # this rcp enforces access controls on S3 buckets by requiring kms encryption and a minimum TLS version
      policy_name     = "rcp_enforce_s3_encryption_and_tls_version"
      policy_type     = "RESOURCE_CONTROL_POLICY"
      target_ou_paths = ["/root"]
      template_names  = ["enforce_s3_kms_encryption", "enforce_s3_tls_version"]
      # set the minimum TLS version for access to S3 buckets
      s3_tls_minimum_version = "1.3"
      # add exception for certain resources
      exclude_resource_arns = []
    },
  ]
}