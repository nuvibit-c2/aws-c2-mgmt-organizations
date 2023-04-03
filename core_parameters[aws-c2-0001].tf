locals {
  # core_parameters = module.core_parameters_s3_reader_0001.parameter_map
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ CORE PARAMETERS READER
# ---------------------------------------------------------------------------------------------------------------------
module "core_parameters_s3_reader_0001" {
  source = "github.com/nuvibit/terraform-aws-core-parameters-s3//modules/reader?ref=feat-init"

  bucket_name = "poc-core-parameters-s3"

  providers = {
    aws = aws.aws-c2-0001
  }
}








# ---------------------------------------------------------------------------------------------------------------------
# ¦ CROSS ACCOUNT TESTING [aws-c2-0001]
# ---------------------------------------------------------------------------------------------------------------------
provider "aws" {
  alias  = "aws-c2-0001"
  region = "eu-central-1"
  assume_role {
    role_arn = "arn:aws:iam::945766593056:role/OrganizationAccountAccessRole"
  }
}