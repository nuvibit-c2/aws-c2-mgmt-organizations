provider "aws" {
  region = local.main_region
}

locals {
    # set the main region where boostrap resource should be deployed
    main_region     = "eu-central-2"
    account_name    = "xxx-org-mgmt-organizations"
    bucket_suffix   = "-tofu-state"
    # for terraform xx and opentofu xx dynamodb is not required for state locking
    create_dynamodb = false
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ NTC BOOTSTRAP - S3 BACKEND + OIDC CONFIGURATION
# ---------------------------------------------------------------------------------------------------------------------
# this module needs to be deployed once from a local state
# after that delete this configuration and the local state
# use new s3 backend to continue with ntc deployment
module "ntc_bootstrap" {
  source = "github.com/nuvibit-terraform-collection/terraform-aws-ntc-bootstrap?ref=setup-tfstate-management-requirements"

  s3_bucket_name             = "${local.account_name}$local.bucket_suffix"
  create_s3_state_bucket     = true
  create_dynamodb_lock_table = false

  # create an oicd provider and iam role to grant github actions deployment permissions
  oidc_configurations = [
    {
      provider_url   = "https://token.actions.githubusercontent.com"
      client_id_list = ["sts.amazonaws.com"]
      roles = [
        {
          role_name   = "ntc-terratest-oidc-role"
          description = "OIDC Role for GitHub Actions deployment"
          assume_role_policy_conditions = [
            {
              test     = "StringEquals"
              variable = "token.actions.githubusercontent.com:sub"
              values   = ["repo:nuvibit-terraform-collection/terraform-*:*"]
            }
          ]
          managed_policy_arns           = ["arn:aws:iam::aws:policy/AdministratorAccess"]
          max_session_duration_in_hours = 1
        }
      ]
    }
  ]
}