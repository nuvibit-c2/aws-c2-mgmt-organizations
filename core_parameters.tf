locals {
  parameter_nodes = [
    {
      "node_name"             = "org_management",
      "node_owner_account_id" = "228120440352"
    },
    {
      "node_name"             = "core_connectivity"
      "node_owner_account_id" = "944538260333"
    },
    {
      "node_name"             = "core_security"
      "node_owner_account_id" = "769269768678"
    }
  ]

  core_parameters = module.core_parameters_s3_reader_org_mgmt.parameter_map

  # this parameter node is managed by org_mgmt account
  parameters_org_management = {
    # this node contains global parameters which are used across entire organization
    "global" : { "core_regions" : ["eu-central-1", "eu-central-2"], "env_prefix" : "fdnt", "env_suffix" : "p" },
    # this node contains module parameters which are provisioned in org_mgmt account
    "sso_module" : { "input1" : "value1", "input2" : ["value2"], "input3" : 3 },
    "organization_module" : { "input1" : "value1", "input2" : ["value2"], "input3" : 3 },
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ CORE PARAMETERS S3 BUCKET
# ---------------------------------------------------------------------------------------------------------------------
module "core_parameters_s3" {
  source = "github.com/nuvibit/terraform-aws-core-parameters-s3?ref=feat-init"

  bucket_name     = "poc-core-parameters-s3"
  org_id          = data.aws_organizations_organization.current.id
  parameter_nodes = local.parameter_nodes
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ CORE PARAMETERS READER
# ---------------------------------------------------------------------------------------------------------------------
module "core_parameters_s3_reader_org_mgmt" {
  source = "github.com/nuvibit/terraform-aws-core-parameters-s3//modules/reader?ref=feat-init"

  bucket_name = "poc-core-parameters-s3"
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ CORE PARAMETERS WRITER
# ---------------------------------------------------------------------------------------------------------------------
module "core_parameters_s3_writer_org_mgmt" {
  source = "github.com/nuvibit/terraform-aws-core-parameters-s3//modules/writer?ref=feat-init"

  bucket_name     = "poc-core-parameters-s3"
  parameter_node  = "org_management"
  node_parameters = local.parameters_org_management
}