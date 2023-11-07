# ---------------------------------------------------------------------------------------------------------------------
# ¦ NTC SERVICE CONTROL POLICY TEMPLATES
# ---------------------------------------------------------------------------------------------------------------------
module "service_control_policy_templates" {
  source = "github.com/nuvibit-terraform-collection/terraform-aws-ntc-scp-templates?ref=1.0.0"

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
}