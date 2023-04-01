locals {
  parameter_nodes = [
    {
      "node_name" : "org_management",
      "node_owner_account_id" = "228120440352"
    },
    {
      "node_name" : "core_connectivity"
      "node_owner_account_id" = "944538260333"
    }
  ]

  core_parameters = {
    org_management : { # this parameter node is managed by org_mgmt account
      # this node contains global parameters which are used across entire organization
      "global" : { "core_regions" : ["eu-central-1", "eu-central-2"], "env_prefix" : "fdnt", "env_suffix" : "p" },
      # this node contains module parameters which are provisioned in org_mgmt account
      "sso_module" : { "input1" : "value1", "input2" : ["value2"], "input3" : 3 },
      "organization_module" : { "input1" : "value1", "input2" : ["value2"], "input3" : 3 },
    },
    core_connectivity : { # this parameter node is managed by core_connectivity account
      # this node contains module parameters which are provisioned in core_connectivity account
      "vpc_module" : { "input1" : "value1", "input2" : ["value2"], "input3" : 3 },
      "ipam_module" : { "input1" : "value1", "input2" : ["value2"], "input3" : 3 },
    },
    core_security : { # this parameter node is managed by core_security account
      # this node contains module parameters which are provisioned in core_security account
      "config_module" : { "input1" : "value1", "input2" : ["value2"], "input3" : 3 },
      "config_member_module" : { "input1" : "value1", "input2" : ["value2"], "input3" : 3 },
    },
    core_provisioning : { # this parameter node is managed by core_provisioning account
      # this node contains module parameters which are provisioned in core_provisioning account
      "account_lifecycle_module" : { "input1" : "value1", "input2" : ["value2"], "input3" : 3 },
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ PROVIDERS
# ---------------------------------------------------------------------------------------------------------------------
provider "aws" {
  alias  = "aws-c2-org-mgmt"
  region = "eu-central-1"
  assume_role {
    role_arn = "arn:aws:iam::228120440352:role/OrganizationAccountAccessRole"
  }
}

provider "aws" {
  alias  = "aws-c2-connectivity"
  region = "eu-central-1"
  assume_role {
    role_arn = "arn:aws:iam::944538260333:role/OrganizationAccountAccessRole"
  }
}

provider "aws" {
  alias  = "aws-c2-0001"
  region = "eu-central-1"
  assume_role {
    role_arn = "arn:aws:iam::945766593056:role/OrganizationAccountAccessRole"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ CORE PARAMETERS S3 [aws-c2-org-mgmt]
# ---------------------------------------------------------------------------------------------------------------------
module "core_parameters_s3" {
  source = "github.com/nuvibit/terraform-aws-core-parameters-s3?ref=feat-init"

  bucket_name     = "poc-core-parameters-s3"
  org_id          = data.aws_organizations_organization.current.id
  parameter_nodes = local.parameter_nodes

  providers = {
    aws = aws.aws-c2-org-mgmt
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ CORE PARAMETERS S3 - WRITER [aws-c2-org-mgmt]
# ---------------------------------------------------------------------------------------------------------------------
module "core_parameters_s3_writer_org_mgmt" {
  source = "github.com/nuvibit/terraform-aws-core-parameters-s3//modules/writer?ref=feat-init"

  bucket_name     = "poc-core-parameters-s3"
  parameter_node  = "org_management"
  node_parameters = local.core_parameters.org_management

  providers = {
    aws = aws.aws-c2-org-mgmt
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ CORE PARAMETERS S3 - WRITER [aws-c2-connectivity]
# ---------------------------------------------------------------------------------------------------------------------
# module "core_parameters_s3_writer_connectivity" {
#   source = "github.com/nuvibit/terraform-aws-core-parameters-s3//modules/writer?ref=feat-init"

#   bucket_name     = "poc-core-parameters-s3"
#   parameter_node  = "core_connectivity"
#   node_parameters = local.core_parameters.core_connectivity

#   providers = {
#     aws = aws.aws-c2-connectivity
#   }
# }

# # ---------------------------------------------------------------------------------------------------------------------
# # ¦ CORE PARAMETERS S3 - READER [aws-c2-0001]
# # ---------------------------------------------------------------------------------------------------------------------
# module "core_parameters_s3_reader_0001" {
#   source = "github.com/nuvibit/terraform-aws-core-parameters-s3//modules/reader?ref=feat-init"

#   bucket_name = "poc-core-parameters-s3"

#   providers = {
#     aws = aws.aws-c2-0001
#   }

#   depends_on = [
#     module.core_parameters_s3_writer_org_mgmt,
#     module.core_parameters_s3_writer_connectivity
#   ]
# }

# # ---------------------------------------------------------------------------------------------------------------------
# # ¦ OUTPUTS
# # ---------------------------------------------------------------------------------------------------------------------
# output "core_parameters" {
#   value = module.core_parameters_s3_reader_0001.parameter_map
# }
# output "parameter_nodes" {
#   value = module.core_parameters_s3_reader_0001.parameter_nodes
# }
