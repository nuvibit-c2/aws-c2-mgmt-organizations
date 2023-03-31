locals {
  parameter_node = [
    {
      "node_name": "org_management",
      "node_owner_account_id" = "228120440352"
    },
    {
      "node_name": "core_connectivity"
      "node_owner_account_id" = "944538260333"
    }
  ]
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ CORE PARAMETERS S3
# ---------------------------------------------------------------------------------------------------------------------
module "core_parameters_s3" {
  source = "./modules/core-parameters-s3"

  bucket_name = "poc-core-parameters-s3"
  org_id = data.aws_organizations_organization.current.id
  parameter_nodes = local.core_parameters
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ CORE PARAMETERS S3 - READER
# ---------------------------------------------------------------------------------------------------------------------
# module "core_parameters_s3_reader" {
#   source = "./modules/core-parameters-s3"

#   bucket_name = "poc-core-parameters-s3"
# }

# ---------------------------------------------------------------------------------------------------------------------
# ¦ CORE PARAMETERS S3 - WRITER
# ---------------------------------------------------------------------------------------------------------------------
# module "core_parameters_s3_writer" {
#   source = "./modules/core-parameters-s3"

#   bucket_name = "poc-core-parameters-s3"
# }