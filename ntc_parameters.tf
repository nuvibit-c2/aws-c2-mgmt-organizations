locals {
  ntc_parameters = module.ntc_parameters_reader.parameter_map
  ntc_parameters_management = {
    # this node contains global parameters which are used across entire organization
    "global" : { "core_regions" : ["eu-central-1", "eu-central-2"], "env_prefix" : "fdnt", "env_suffix" : "p" },
    # this node contains module parameters which are provisioned in org_mgmt account
    "sso_module" : { "input1" : "value1", "input2" : ["value2"], "input3" : 3 },
    "organization_module" : { "input1" : "value1", "input2" : ["value2"], "input3" : 3 },
  }
  ntc_parameter_nodes = [
    {
      "node_name"             = "management",
      "node_owner_account_id" = "228120440352"
    },
    {
      "node_name"             = "connectivity"
      "node_owner_account_id" = "944538260333"
    },
    {
      "node_name"             = "security"
      "node_owner_account_id" = "769269768678"
    }
  ]
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ CORE PARAMETERS - BUCKET OWNER
# ---------------------------------------------------------------------------------------------------------------------
module "ntc_parameters_bucket" {
  source = "github.com/nuvibit/terraform-aws-ntc-parameters?ref=feat-init"

  bucket_name     = "ntc-parameters-c2"
  org_id          = data.aws_organizations_organization.current.id
  parameter_nodes = local.ntc_parameter_nodes
  force_destroy   = false
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ CORE PARAMETERS - READER
# ---------------------------------------------------------------------------------------------------------------------
module "ntc_parameters_reader" {
  source      = "github.com/nuvibit/terraform-aws-ntc-parameters//modules/reader?ref=feat-init"
  depends_on  = [module.ntc_parameters_bucket]

  bucket_name = "ntc-parameters-c2"
}

# # ---------------------------------------------------------------------------------------------------------------------
# # ¦ CORE PARAMETERS - WRITER
# # ---------------------------------------------------------------------------------------------------------------------
# module "core_parameters_writer" {
#   source      = "github.com/nuvibit/terraform-aws-ntc-parameters//modules/writer?ref=feat-init"
#   depends_on  = [module.ntc_parameters_bucket]

#   bucket_name     = "ntc-parameters-c2"
#   parameter_node  = "management"
#   node_parameters = local.ntc_parameters_management
# }
