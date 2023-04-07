locals {
  # core_parameters = module.core_parameters_s3_reader_0001.parameter_map
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ CORE PARAMETERS - READER
# ---------------------------------------------------------------------------------------------------------------------
module "core_parameters_s3_reader_0001" {
  source = "github.com/nuvibit/terraform-aws-ntc-parameters//modules/reader?ref=feat-init"

  bucket_name = "poc-core-parameters-s3"

  providers = {
    aws = aws.aws-c2-0001
  }
}
