locals {
  # map of parameters merged from all parameter nodes
  ntc_parameters = module.ntc_parameters_reader.parameter_map

  # parameters that are managed by org management account
  ntc_parameters_management = {
    global : {
      "core_regions" : ["eu-central-1", "eu-central-2"]
      "workload_regions" : ["eu-central-1", "eu-central-2"]
      "baseline_regions" : ["eu-central-1", "eu-central-2", "us-east-1"]
    }
    identity_center : {}
    organization : {
      "org_id" : module.organization.organization_id
      "ou_ids" : module.organization.organizational_unit_ids
      "core_account_ids" : local.organization_core_account_ids
    }
  }

  # the ntc parameter bucket should ideally be created in org management account
  ## all organization accounts are granted read permission for all parameters
  ## only the parameter node owner account is granted write access to his corresponding parameters
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
# ¦ NTC PARAMETERS - BUCKET (DEPLOY FIRST)
# ---------------------------------------------------------------------------------------------------------------------
module "ntc_parameters_bucket" {
  source = "github.com/nuvibit-terraform-collection/terraform-aws-ntc-parameters?ref=beta"

  bucket_name     = "ntc-parameters-c2"
  org_id          = module.organization.organization_id
  parameter_nodes = local.ntc_parameter_nodes
  account_map     = local.organization_accounts_enriched
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ NTC PARAMETERS - READER
# ---------------------------------------------------------------------------------------------------------------------
module "ntc_parameters_reader" {
  source = "github.com/nuvibit-terraform-collection/terraform-aws-ntc-parameters//modules/reader?ref=beta"

  bucket_name = "ntc-parameters-c2"
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ NTC PARAMETERS - WRITER
# ---------------------------------------------------------------------------------------------------------------------
module "core_parameters_writer" {
  source = "github.com/nuvibit-terraform-collection/terraform-aws-ntc-parameters//modules/writer?ref=beta"

  bucket_name     = "ntc-parameters-c2"
  parameter_node  = "management"
  node_parameters = local.ntc_parameters_management
}