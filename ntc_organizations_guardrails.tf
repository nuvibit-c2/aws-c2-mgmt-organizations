# ---------------------------------------------------------------------------------------------------------------------
# ¦ NTC GUARDRAIL TEMPLATES
# ---------------------------------------------------------------------------------------------------------------------
module "ntc_guardrail_templates" {
  # source = "github.com/nuvibit-terraform-collection/terraform-aws-ntc-guardrail-templates?ref=1.0.3"
  source = "github.com/nuvibit-terraform-collection/terraform-aws-ntc-guardrail-templates?ref=feat-deny-root-access"

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
      policy_name            = "scp_suspended_ou"
      target_ou_paths        = ["/root/suspended", "/root/decommission"]
      template_names         = ["deny_all"]
      exclude_principal_arns = ["arn:aws:iam::*:role/OrganizationAccountAccessRole"]
    },
    {
      # this scp denys all actions outside allowed regions except global services
      policy_name     = "scp_workloads_ou"
      target_ou_paths = ["/root/workloads"]
      template_names  = ["deny_outside_allowed_regions"]
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
    }
  ]
}