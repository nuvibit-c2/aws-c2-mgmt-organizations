# =====================================================================================================================
# NTC PARAMETERS - CROSS-ACCOUNT CONFIGURATION SHARING
# =====================================================================================================================
# The NTC Parameters system provides a centralized, secure way to share configuration data across AWS accounts
# in your organization. Think of it as a distributed key-value store accessible to all accounts.
#
# WHY USE NTC PARAMETERS?
# -----------------------
# Problem: Terraform modules in different accounts need to reference outputs from other accounts
# 
# Traditional Solutions (and their problems):
#   ❌ Hardcode values: Not dynamic, breaks when resources change
#   ❌ AWS SSM Parameter Store: Complex cross-account access (requires assume role to write parameters)
#   ❌ Terraform remote state: Tight coupling, security concerns with state file access
#   ❌ Manual coordination: Error-prone, doesn't scale
#
# NTC Parameters Solution:
#   ✅ Centralized S3 bucket stores all parameters
#   ✅ Each account writes to its own "parameter node" (namespace)
#   ✅ All organization accounts can read all parameters
#   ✅ No circular dependencies or tight coupling
#   ✅ Automatic drift detection and updates
#
# HOW IT WORKS:
# -------------
# 1. Management account creates S3 bucket with organization-wide read access
# 2. Each account writes its outputs to a dedicated parameter node:
#    - mgmt-organizations → org_id, ou_ids, etc.
#    - connectivity → vpc_ids, subnet_ids, transit_gateway_id
#    - log-archive → s3_bucket_name, kms_key_arn
# 3. Any account reads parameters using the reader module
# 4. Parameters are referenced via: local.ntc_parameters["node-name"]["key"]
# =====================================================================================================================

# ---------------------------------------------------------------------------------------------------------------------
# LOCAL VARIABLES - NTC PARAMETERS CONFIGURATION
# ---------------------------------------------------------------------------------------------------------------------
locals {
  # -------------------------------------------------------------------------------------------------------------------
  # S3 Bucket Name
  # -------------------------------------------------------------------------------------------------------------------
  # Centralized parameter storage bucket (created by mgmt-organizations)
  # ⚠️  Must match the bucket name across all accounts in the organization
  # -------------------------------------------------------------------------------------------------------------------
  ntc_parameters_bucket_name = "aws-c2-ntc-parameters"

  # -------------------------------------------------------------------------------------------------------------------
  # Parameter Node Name
  # -------------------------------------------------------------------------------------------------------------------
  # This account's namespace in the parameter bucket
  # Convention: <account-type>-<account-purpose>
  # -------------------------------------------------------------------------------------------------------------------
  ntc_parameters_writer_node = "mgmt-organizations"

  # -----------------------------------------------------
  # PARAMETERS TO WRITE (from this account)
  # -----------------------------------------------------
  # These organization metadata parameters are consumed by:
  #   - Account Factory (for attaching policies to accounts)
  #   - Other services needing org structure information
  #   - Guardrail templates (for org_id in RCPs)
  # -----------------------------------------------------
  ntc_parameters_to_write = {
    "org_id"         = module.ntc_organizations.org_id                     # AWS Organization ID (e.g., o-xxxxx)
    "org_root_ou_id" = module.ntc_organizations.org_root_ou_id             # Root OU ID (e.g., r-xxxxx)
    "ou_ids"         = module.ntc_organizations.organizational_unit_ids    # Map of OU names to IDs
    "ou_path_ids"    = module.ntc_organizations.organization_unit_path_ids # Map of OU paths to IDs
  }

  # -----------------------------------------------------
  # PARAMETERS TO READ (from all accounts)
  # -----------------------------------------------------
  # This contains ALL parameters from ALL parameter nodes
  # Access pattern: local.ntc_parameters["node-name"]["key"]
  # Examples:
  #   - local.ntc_parameters["mgmt-organizations"]["org_id"]
  #   - local.ntc_parameters["connectivity"]["transit_gateway_id"]
  # -----------------------------------------------------
  ntc_parameters = module.ntc_parameters_reader.all_parameters
}

# =====================================================================================================================
# NTC PARAMETERS BUCKET - CENTRALIZED STORAGE
# =====================================================================================================================
# Creates the S3 bucket that stores all parameters and configures access policies
#
# WHAT THIS MODULE DOES:
# ----------------------
# 1. Creates S3 bucket with versioning and encryption
# 2. Configures bucket policy allowing:
#    - Read access to all organization accounts (aws:PrincipalOrgID)
#    - Write access to specific accounts based on parameter_nodes configuration
# 3. Sets up parameter node structure (namespaces for each account/service)
# 4. Enables lifecycle policies for cost optimization
#
# BUCKET POLICY LOGIC:
# -------------------
# Read Access:
#   - Principal: ANY principal in the organization
#   - Condition: aws:PrincipalOrgID = <your-org-id>
#   - Actions: s3:GetObject, s3:ListBucket
#   - Effect: All accounts can read all parameters
#
# Write Access (per parameter node):
#   - Principal: Specific account ID (node_owner_account_id)
#   - Resource: s3://bucket/<node_name>/*
#   - Actions: s3:PutObject, s3:DeleteObject
#   - Effect: Each account can only write to its own parameter node
#
# PARAMETER NODES:
# ----------------
# Each parameter node represents a namespace for a specific account or service
# Structure: <node_name>/ (e.g., mgmt-organizations/, connectivity/)
#
# ACCOUNT FACTORY SPECIAL FLAG:
# -----------------------------
# node_owner_is_account_factory = true
#   - Grants permission to store account map in ntc-parameters
#
# DEPLOYMENT:
# -----------
# ⚠️  Deploy this module FIRST in management account before any other accounts
# ⚠️  Other accounts will fail if bucket doesn't exist yet
# =====================================================================================================================
module "ntc_parameters_bucket" {
  source = "github.com/nuvibit-terraform-collection/terraform-aws-ntc-parameters?ref=1.1.4"

  bucket_name = local.ntc_parameters_bucket_name

  # Grant read access to ALL organization members via PrincipalOrgID condition
  # This allows any account in the organization to read parameters from any node
  org_id = local.organization_id

  # -----------------------------------------------------
  # PARAMETER NODES CONFIGURATION
  # -----------------------------------------------------
  # Define which accounts can write to which parameter nodes (namespaces)
  # Each account gets write access ONLY to its own parameter node
  # All accounts get read access to ALL parameter nodes
  # -----------------------------------------------------
  parameter_nodes = [
    # ---------------------------------------------------
    # MANAGEMENT ACCOUNT - Organizations
    # ---------------------------------------------------
    # Stores: org_id, ou_ids, ou_path_ids
    # Used by: All accounts needing organization structure
    # ---------------------------------------------------
    {
      "node_name"             = "mgmt-organizations",
      "node_owner_account_id" = local.current_account_id
    },
    # ---------------------------------------------------
    # MANAGEMENT ACCOUNT - Account Factory
    # ---------------------------------------------------
    # Stores: account information and account inventory
    # Used by: orchestration where account information is needed
    # ---------------------------------------------------
    {
      "node_name"                     = "mgmt-account-factory",
      "node_owner_account_id"         = local.current_account_id
      "node_owner_is_account_factory" = true # Grants permission to store account map
    },
    # ---------------------------------------------------
    # MANAGEMENT ACCOUNT - Identity Center (SSO)
    # ---------------------------------------------------
    # Stores: SSO instance ARN, permission sets, groups
    # Used by: Accounts needing SSO integration
    # ---------------------------------------------------
    {
      "node_name"             = "mgmt-identity-center",
      "node_owner_account_id" = local.current_account_id
    },
    # ---------------------------------------------------
    # SECURITY TOOLING ACCOUNT
    # ---------------------------------------------------
    # Stores: Security Tooling SNS topics
    # Used by: Member accounts for security service delegation
    # ---------------------------------------------------
    {
      "node_name"             = "security-tooling"
      "node_owner_account_id" = local.security_account_id
    },
    # ---------------------------------------------------
    # LOG ARCHIVE ACCOUNT
    # ---------------------------------------------------
    # Stores: Log archive buckets, KMS key ARNs
    # Used by: All accounts for centralized audit logs
    # ---------------------------------------------------
    {
      "node_name"             = "log-archive"
      "node_owner_account_id" = local.log_archive_account_id
    },
    # ---------------------------------------------------
    # CONNECTIVITY/NETWORK ACCOUNT
    # ---------------------------------------------------
    # Stores: Transit Gateway ID, IPAM pool IDs, Prefix lists
    # Used by: Workload accounts for network connectivity
    # ---------------------------------------------------
    {
      "node_name"             = "connectivity"
      "node_owner_account_id" = local.connectivity_account_id
    },
    # ---------------------------------------------------
    # CENTRAL BACKUP ACCOUNT
    # ---------------------------------------------------
    # Stores: Backup vault ARNs, KMS key for backups,
    #         backup policies, cross-account role ARNs
    # Used by: Accounts implementing centralized backups
    # ---------------------------------------------------
    {
      "node_name"             = "central-backup"
      "node_owner_account_id" = local.backup_account_id
    },
  ]

  providers = {
    aws = aws.euc1
  }
}

# =====================================================================================================================
# NTC PARAMETERS READER - READ PARAMETERS FROM ALL NODES
# =====================================================================================================================
# Reads and merges parameters from ALL parameter nodes in the S3 bucket
#
# WHAT THIS MODULE DOES:
# ----------------------
# 1. Lists all objects in the S3 bucket (all parameter nodes)
# 2. Downloads and parses each parameter node's JSON file
# 3. Merges all parameters into a single map structure
# 4. Makes them available via: 'module.ntc_parameters_reader.all_parameters'
#
# OUTPUT STRUCTURE:
# -----------------
# {
#   "mgmt-organizations" = {
#     "org_id" = "o-xxxxx",
#     "ou_ids" = {...}
#   },
#   "connectivity" = {
#     "vpc_id" = "vpc-xxxxx",
#     "subnet_ids" = [...]
#   },
#   "security-tooling" = {
#     "guardduty_detector_id" = "xxxxx"
#   }
# }
#
# USAGE EXAMPLES:
# ---------------
# Access organization ID:
#   local.ntc_parameters["mgmt-organizations"]["org_id"]
#
# Access Transit Gateway ID from connectivity account:
#   local.ntc_parameters["connectivity"]["transit_gateway_id"]
#
# Access core account IDs:
#   local.ntc_parameters["mgmt-account-factory"]["core_accounts"]["INSERT_ACCOUNT_NAME"]
# =====================================================================================================================
module "ntc_parameters_reader" {
  source = "github.com/nuvibit-terraform-collection/terraform-aws-ntc-parameters//modules/reader?ref=1.1.4"

  bucket_name = local.ntc_parameters_bucket_name

  providers = {
    aws = aws.euc1
  }
}

# =====================================================================================================================
# NTC PARAMETERS WRITER - WRITE THIS ACCOUNT'S PARAMETERS
# =====================================================================================================================
# Writes this account's parameters to its dedicated parameter node in the S3 bucket
#
# WHAT THIS MODULE DOES:
# ----------------------
# 1. Takes parameters from node_parameters input
# 2. Converts them to JSON format
# 3. Writes to S3: s3://<bucket>/<parameter_node>/parameters.json
# 4. Other accounts can immediately read the updated parameters
#
# WRITE PERMISSIONS:
# ------------------
# This account can ONLY write to its own parameter node (mgmt-identity-center)
# Attempting to write to another node will fail with S3 AccessDenied
#
# REPLACE_PARAMETERS BEHAVIOR:
# ----------------------------
# replace_parameters = true (RECOMMENDED):
#   • Completely replaces the parameter node content on each run
#   • Ensures parameters stay in sync with Terraform state
#   • Removes any manually added parameters
#   • Prevents parameter drift
#
# replace_parameters = false:
#   • Merges new parameters with existing ones
#   • Manually added parameters are preserved
#   • Risk of stale parameters accumulating over time
#   • Use only if you need to manually manage some parameters
#
# WRITE TIMING:
# -------------
# ⚠️  Parameters are written AFTER all resources are created
# ⚠️  Other accounts may see stale parameters until this run completes
#
# WHAT TO WRITE:
# --------------
# DO write:
#   ✓ Resource IDs (VPC IDs, subnet IDs, account IDs)
#   ✓ ARNs (KMS keys, SNS topics, IAM roles)
#   ✓ Configuration values (CIDR blocks, region lists)
#   ✓ Non-sensitive metadata
#
# DO NOT write:
#   ✗ Secrets, passwords, API keys (use AWS Secrets Manager instead)
#   ✗ Sensitive data (use proper secrets management)
#   ✗ Frequently changing data (use SSM Parameter Store for dynamic values)
#   ✗ Large binary data (parameters should be small JSON-serializable values)
# =====================================================================================================================
module "ntc_parameters_writer" {
  source = "github.com/nuvibit-terraform-collection/terraform-aws-ntc-parameters//modules/writer?ref=1.1.4"

  bucket_name        = local.ntc_parameters_bucket_name # S3 bucket for parameter storage
  parameter_node     = local.ntc_parameters_writer_node # This account's namespace
  node_parameters    = local.ntc_parameters_to_write    # Parameters to write
  replace_parameters = true                             # Always replace (prevent drift)

  providers = {
    aws = aws.euc1
  }
}