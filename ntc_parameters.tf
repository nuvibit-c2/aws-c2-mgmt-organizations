locals {
  ntc_parameters = module.ntc_parameters_reader.parameter_map
  # parameters that are managed by org management account
  ntc_parameters_management = {
    global : {
      "core_regions" : ["eu-central-1", "eu-central-2"]
      "env_prefix" : "fdnt"
      "env_suffix" : "p"
      "account_map" : local.organization_accounts_enriched
      "org_id" : module.organization.organization_id
    },
    identity_center_module : {
      "input1" : "value1"
      "input2" : ["value2"]
      "input3" : 3
    },
    organization_module : {
      "input1" : "value1"
      "input2" : ["value2"]
      "input3" : 3
    },
  }
  # all organization accounts have read permission for all parameters
  # only parameter node owners have write access in the corresponding parameter node
  ntc_parameter_nodes = [
    {
      "node_name"             = "management",
      "node_owner_account_id" = local.organization_account_ids["aws-c2-management"]
    },
    {
      "node_name"             = "connectivity"
      "node_owner_account_id" = local.organization_account_ids["aws-c2-connectivity"]
    },
    {
      "node_name"             = "security"
      "node_owner_account_id" = local.organization_account_ids["aws-c2-security"]
    },
    {
      "node_name"             = "log-archive"
      "node_owner_account_id" = local.organization_account_ids["aws-c2-log-archive"]
    }
  ]
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ CORE PARAMETERS - BUCKET (DEPLOY FIRST)
# ---------------------------------------------------------------------------------------------------------------------
module "ntc_parameters_bucket" {
  source = "github.com/nuvibit/terraform-aws-ntc-parameters?ref=beta"

  bucket_name     = "ntc-parameters-c2"
  org_id          = module.organization.organization_id
  parameter_nodes = local.ntc_parameter_nodes
  force_destroy   = false
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ CORE PARAMETERS - READER
# ---------------------------------------------------------------------------------------------------------------------
module "ntc_parameters_reader" {
  source = "github.com/nuvibit/terraform-aws-ntc-parameters//modules/reader?ref=beta"

  bucket_name = "ntc-parameters-c2"
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ CORE PARAMETERS - WRITER
# ---------------------------------------------------------------------------------------------------------------------
module "core_parameters_writer" {
  source = "github.com/nuvibit/terraform-aws-ntc-parameters//modules/writer?ref=beta"

  bucket_name     = "ntc-parameters-c2"
  parameter_node  = "management"
  node_parameters = local.ntc_parameters_management
}
