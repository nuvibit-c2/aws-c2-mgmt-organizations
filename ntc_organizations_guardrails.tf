# ---------------------------------------------------------------------------------------------------------------------
# ¦ NTC GUARDRAIL TEMPLATES
# ---------------------------------------------------------------------------------------------------------------------
module "ntc_guardrail_templates" {
  source = "github.com/nuvibit-terraform-collection/terraform-aws-ntc-guardrail-templates?ref=1.0.3"

  # service control policies (SCPs) can apply permission guardrails at the organization, organizational unit, or account level
  # https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_scps.html
  service_control_policy_templates = [
    {
      policy_name     = "scp_root_ou"
      target_ou_paths = ["/root"]
      template_names  = ["deny_leaving_organizations", "deny_actions_as_root"]
    },
    {
      policy_name            = "scp_suspended_ou"
      target_ou_paths        = ["/root/suspended", "/root/decommission"]
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
}