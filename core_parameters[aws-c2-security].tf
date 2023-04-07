locals {
  # core_parameters = module.core_parameters_s3_reader_security.parameter_map

  # this parameter node is managed by core_security account
  parameters_core_security = {
    # this node contains module parameters which are provisioned in core_security account
    "config_module" : { "input1" : "value1", "input2" : ["value2"], "input3" : 3 },
    "config_module_member" : { "input1" : "value1", "input2" : ["value2"], "input3" : 3 },
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ CORE PARAMETERS - READER
# ---------------------------------------------------------------------------------------------------------------------
module "core_parameters_s3_reader_security" {
  source = "github.com/nuvibit/terraform-aws-ntc-parameters-s3//modules/reader?ref=feat-init"

  bucket_name = "poc-core-parameters-s3"
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ CORE PARAMETERS - WRITER
# ---------------------------------------------------------------------------------------------------------------------
module "core_parameters_s3_writer_security" {
  source = "github.com/nuvibit/terraform-aws-ntc-parameters-s3//modules/writer?ref=feat-init"

  bucket_name     = "poc-core-parameters-s3"
  parameter_node  = "core_security"
  node_parameters = local.parameters_core_security

  providers = {
    aws = aws.aws-c2-security
  }
}
