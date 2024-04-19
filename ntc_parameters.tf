locals {
  ntc_parameters_bucket_name = "aws-c2-ntc-parameters"
  ntc_parameters_writer_node = "mgmt-organizations"

  # parameters that are managed by org management account
  ntc_parameters_to_write = {
    core_regions     = ["eu-central-1", "eu-central-2"]
    workload_regions = ["eu-central-1", "eu-central-2"]
    org_id           = module.ntc_organizations.org_id
    org_root_ou_id   = module.ntc_organizations.org_root_ou_id
    ou_ids           = module.ntc_organizations.organizational_unit_ids
  }

  # by default existing node parameters will be merged with new parameters to avoid deleting parameters
  ntc_replace_parameters = true

  # map of parameters merged from all parameter nodes
  ntc_parameters = module.ntc_parameters_reader.all_parameters
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ NTC PARAMETERS - READER
# ---------------------------------------------------------------------------------------------------------------------
module "ntc_parameters_reader" {
  source = "github.com/nuvibit-terraform-collection/terraform-aws-ntc-parameters//modules/reader?ref=1.1.2"

  bucket_name = local.ntc_parameters_bucket_name

  providers = {
    aws = aws.euc1
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ NTC PARAMETERS - WRITER
# ---------------------------------------------------------------------------------------------------------------------
module "ntc_parameters_writer" {
  source = "github.com/nuvibit-terraform-collection/terraform-aws-ntc-parameters//modules/writer?ref=1.1.2"

  bucket_name        = local.ntc_parameters_bucket_name
  parameter_node     = local.ntc_parameters_writer_node
  node_parameters    = local.ntc_parameters_to_write
  replace_parameters = local.ntc_replace_parameters

  providers = {
    aws = aws.euc1
  }
}