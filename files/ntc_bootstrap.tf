# ---------------------------------------------------------------------------------------------------------------------
# ¦ PROVIDER CONFIGURATION
# ---------------------------------------------------------------------------------------------------------------------
provider "aws" {
  region = local.main_region
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ CONFIGURATION VARIABLES
# ---------------------------------------------------------------------------------------------------------------------
locals {
  # Primary AWS region for deploying bootstrap infrastructure
  # This should match your organization's primary operating region
  main_region = "INSERT_REGION" # e.g. "eu-central-2"

  # AWS account name identifier for the bootstrap resources
  # IMPORTANT: This must be the AWS Organizations management account
  # Replace "INSERT_ACCOUNT_NAME" with your actual account name/identifier
  account_name = "INSERT_ACCOUNT_NAME" # e.g. "aws-c2-management"

  # Suffix for the Terraform/OpenTofu state bucket name
  # Final bucket name will be: {account_name}{bucket_suffix}
  bucket_suffix = "-tofu-state"

  # DynamoDB table creation toggle for state locking
  # Modern versions (Terraform >= 1.9.0, OpenTofu >= 1.10.0) can use native S3 locking
  # Set to 'true' only if using older versions that require DynamoDB for state locking
  create_dynamodb = false

  # Flag to create the Terraform/OpenTofu state backend file based on the backend configuration
  create_state_backend_file = true
  state_backend_file_path   = "${path.module}/backend.tf"
  state_backend_key_name    = "organizations/tofu.tfstate" # use key prefix for multiple state files in the same bucket
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ NTC BOOTSTRAP MODULE
# ---------------------------------------------------------------------------------------------------------------------
# This bootstrap module sets up initial resources required to start deploying NTC
# 
# DEPLOYMENT WORKFLOW:
# 1. Deploy this module ONCE using local state (terraform apply)
# 2. After successful deployment, delete this bootstrap configuration and local state files
# 3. Configure your backend.tf to use the created S3 bucket
# 4. Continue with NTC deployment using the remote S3 backend
# 5. Resources from the bootstrap module can be imported into the NTC Account Factory Account Baseline at a later stage
#
# CREATED RESOURCES:
# - S3 bucket for storing Terraform / OpenTofu state files
# - KMS key for s3 operations encryption + OpenTofu state encryption. ( existing KMS can key be also used )
# - Optional: DynamoDB table for state locking (legacy versions)
# - Optional: OIDC configuration for CI/CD pipeline authentication
module "ntc_bootstrap" {
  source = "github.com/nuvibit-terraform-collection/terraform-aws-ntc-bootstrap?ref=alpha"

  # S3 bucket configuration for state storage
  s3_state_backend_configuration = {
    create_s3_state_bucket          = true
    s3_bucket_name                  = "${local.account_name}${local.bucket_suffix}"
    create_dynamodb_lock_table      = local.create_dynamodb
    kms_key_deletion_window_in_days = 30
    kms_key_enable_key_rotation     = true
    create_state_backend_file       = local.create_state_backend_file
    state_backend_file_path         = local.state_backend_file_path
    state_backend_key_name          = local.state_backend_key_name
  }

  # (optional) configure OIDC for CI/CD pipeline authentication
  # usually NTC is deployed locally until NTC Account Factory is ready
  # NTC Account Factory can then create OIDC for CI/CD pipelines for all accounts
  oidc_configurations = [
    # EXAMPLE: GitHub Actions OIDC Configuration
    # Uncomment and modify the following block for GitHub Actions integration:
    # {
    #   # GitHub OIDC provider URL (standard for all GitHub repositories)
    #   provider_url   = "https://token.actions.githubusercontent.com"
    #   client_id_list = ["sts.amazonaws.com"]
    #   
    #   roles = [
    #     {
    #       # IAM role name for GitHub Actions authentication
    #       role_name   = "ntc-github-oidc-role"
    #       description = "OIDC Role for GitHub Actions"
    #       
    #       # Repository-specific access control
    #       # Replace ORG_NAME/REPO_NAME with your actual GitHub organization and repository
    #       assume_role_policy_conditions = [
    #         {
    #           test     = "StringEquals"
    #           variable = "token.actions.githubusercontent.com:sub"
    #           values   = ["repo:ORG_NAME/REPO_NAME:*"]
    #         }
    #       ]
    #       
    #       # Terraform / OpenTofu pipelines usually have full access but can also be least-privilege
    #       managed_policy_arns = ["arn:aws:iam::aws:policy/AdministratorAccess"]
    #       
    #       # Session duration in hours (1-12 hours maximum)
    #       max_session_duration_in_hours = 1
    #     }
    #   ]
    # }
  ]
}
