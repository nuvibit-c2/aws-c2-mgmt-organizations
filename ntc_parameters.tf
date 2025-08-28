locals {
  ntc_parameters_bucket_name = "aws-c2-ntc-parameters"
  ntc_parameters_writer_node = "mgmt-organizations"

  # parameters that are managed by org management account
  ntc_parameters_to_write = {
    "org_id"         = module.ntc_organizations.org_id
    "org_root_ou_id" = module.ntc_organizations.org_root_ou_id
    "ou_ids"         = module.ntc_organizations.organizational_unit_ids
    "ou_path_ids"    = module.ntc_organizations.organization_unit_path_ids
  }

  # map of parameters merged from all parameter nodes
  ntc_parameters = module.ntc_parameters_reader.all_parameters
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ NTC PARAMETERS - BUCKET (DEPLOY FIRST)
# ---------------------------------------------------------------------------------------------------------------------
module "ntc_parameters_bucket" {
  source = "github.com/nuvibit-terraform-collection/terraform-aws-ntc-parameters?ref=1.1.4"

  bucket_name = local.ntc_parameters_bucket_name

  # grant read access to parameters for all organization members
  org_id = data.aws_organizations_organization.current.id

  # only the parameter-node owner is granted write access to his corresponding parameters
  parameter_nodes = [
    {
      "node_name"             = "mgmt-organizations",
      "node_owner_account_id" = local.org_account_ids["aws-c2-management"]
    },
    {
      "node_name"                     = "mgmt-account-factory",
      "node_owner_account_id"         = local.org_account_ids["aws-c2-management"]
      "node_owner_is_account_factory" = true
    },
    {
      "node_name"             = "mgmt-identity-center",
      "node_owner_account_id" = local.org_account_ids["aws-c2-management"]
    },
    {
      "node_name"             = "connectivity"
      "node_owner_account_id" = local.org_account_ids["aws-c2-connectivity"]
    },
    {
      "node_name"             = "security-tooling"
      "node_owner_account_id" = local.org_account_ids["aws-c2-security"]
    },
    {
      "node_name"             = "log-archive"
      "node_owner_account_id" = local.org_account_ids["aws-c2-log-archive"]
    }
  ]

  providers = {
    aws = aws.euc1
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ NTC PARAMETERS - READER
# ---------------------------------------------------------------------------------------------------------------------
module "ntc_parameters_reader" {
  source = "github.com/nuvibit-terraform-collection/terraform-aws-ntc-parameters//modules/reader?ref=1.1.4"

  bucket_name = local.ntc_parameters_bucket_name

  providers = {
    aws = aws.euc1
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ NTC PARAMETERS - WRITER
# ---------------------------------------------------------------------------------------------------------------------
module "ntc_parameters_writer" {
  source = "github.com/nuvibit-terraform-collection/terraform-aws-ntc-parameters//modules/writer?ref=1.1.4"

  bucket_name        = local.ntc_parameters_bucket_name
  parameter_node     = local.ntc_parameters_writer_node
  node_parameters    = local.ntc_parameters_to_write
  replace_parameters = true

  providers = {
    aws = aws.euc1
  }
}
