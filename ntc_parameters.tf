locals {
  ntc_parameters_bucket_name = "aws-c2-ntc-parameters"
  ntc_parameters_writer_node = "management"

  # map of parameters merged from all parameter nodes
  ntc_parameters = module.ntc_parameters_reader.all_parameters

  # parameters that are managed by org management account
  ntc_parameters_to_write = {
    global : {
      "core_regions" : ["eu-central-1", "eu-central-2"]
      "workload_regions" : ["eu-central-1", "eu-central-2"]
    }
    organization : {
      "org_id" : module.organizations.org_id
      "org_root_ou_id" : module.organizations.org_root_ou_id
      "ou_ids" : module.organizations.organizational_unit_ids
    }
  }

  # by default existing node parameters will be merged with new parameters to avoid deleting parameters
  replace_parameters = true
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
  node_parameters = local.ntc_parameters_to_write
}