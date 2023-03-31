locals {
  core_parameters = {
    "org_management"  = {
      "account_id" = "123"
      "org_id" = data.aws_organizations_organization.current.id
    }
    "core_provisioning" = {
      "account_id" = "123"
      "iam_role_prefix" = "pipeline_"
    }
    "core_identitiy" = {
      "account_id" = "123"
      "sso_timeout_in_hours" = 10
    }
    "core_connectivity"  = {
      "account_id" = "123"
      "ipam_pool" = "prod_hybrid"
    }
    "core_security"  = {
      "account_id" = "123"
      "controls" = ["cis", "pci-dss"]
    }
    "core_log_archive" = {
      "account_id" = "123"
      "buckets" = ["flow_logs", "config", "guardduty"]
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ CORE PARAMETERS S3
# ---------------------------------------------------------------------------------------------------------------------
module "core_parameters_s3" {
  source = "./modules/core-parameters-s3"

  bucket_name = "poc-core-parameters-s3"
  org_id = data.aws_organizations_organization.current.id
  core_parameters_map = local.core_parameters
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ CORE PARAMETERS S3 - READER
# ---------------------------------------------------------------------------------------------------------------------
module "core_parameters_s3_reader" {
  source = "./modules/core-parameters-s3"

  bucket_name = "poc-core-parameters-s3"
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ CORE PARAMETERS S3 - WRITER
# ---------------------------------------------------------------------------------------------------------------------
# module "core_parameters_s3_writer" {
#   source = "./modules/core-parameters-s3"

#   bucket_name = "poc-core-parameters-s3"
# }