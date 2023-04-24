locals {
  ntc_parameters_bucket_name = "aws-c2-ntc-parameters"
  ntc_parameters_writer_node = "management"

  # map of parameters merged from all parameter nodes
  ntc_parameters = module.ntc_parameters_reader.parameter_map

  # parameters that are managed by org management account
  ntc_parameters_management = {
    global : {
      "core_regions" : ["eu-central-1", "eu-central-2"]
      "workload_regions" : ["eu-central-1", "eu-central-2"]
    }
    organization : {
      "org_id" : module.organization.org_id
      "org_root_ou_id" : module.organization.org_root_ou_id
      "ou_ids" : module.organization.organizational_unit_ids
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ NTC PARAMETERS - READER
# ---------------------------------------------------------------------------------------------------------------------
module "ntc_parameters_reader" {
  source = "github.com/nuvibit-terraform-collection/terraform-aws-ntc-parameters//modules/reader?ref=beta"

  bucket_name = local.ntc_parameters_bucket_name
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ NTC PARAMETERS - WRITER
# ---------------------------------------------------------------------------------------------------------------------
module "ntc_parameters_writer" {
  source = "github.com/nuvibit-terraform-collection/terraform-aws-ntc-parameters//modules/writer?ref=beta"

  bucket_name     = local.ntc_parameters_bucket_name
  parameter_node  = local.ntc_parameters_writer_node
  node_parameters = local.ntc_parameters_management
}