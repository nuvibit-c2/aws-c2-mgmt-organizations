locals {
  # core_parameters = module.core_parameters_s3_reader_connectivity.parameter_map

  # this parameter node is managed by core_connectivity account
  parameters_core_connectivity = {
    # this node contains module parameters which are provisioned in core_connectivity account
    "vpc_module" : { "input1" : "value1", "input2" : ["value2"], "input3" : 3 },
    "ipam_module" : { "input1" : "value1", "input2" : ["value2"], "input3" : 3 },
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ CORE PARAMETERS READER
# ---------------------------------------------------------------------------------------------------------------------
module "core_parameters_s3_reader_connectivity" {
  source = "github.com/nuvibit/terraform-aws-core-parameters-s3//modules/reader?ref=feat-init"

  bucket_name = "poc-core-parameters-s3"
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ CORE PARAMETERS WRITER
# ---------------------------------------------------------------------------------------------------------------------
module "core_parameters_s3_writer_connectivity" {
  source = "github.com/nuvibit/terraform-aws-core-parameters-s3//modules/writer?ref=feat-init"

  bucket_name     = "poc-core-parameters-s3"
  parameter_node  = "core_connectivity"
  node_parameters = local.parameters_core_connectivity

  providers = {
    aws = aws.aws-c2-connectivity
  }
}
