# ---------------------------------------------------------------------------------------------------------------------
# ¦ PROVIDER
# ---------------------------------------------------------------------------------------------------------------------
provider "aws" {
  region = "eu-central-1"
}

provider "aws" {
  alias  = "euc1"
  region = "eu-central-1"
}

# provider for us-east-1 region is sometimes required for specific features or services
provider "aws" {
  alias  = "use1"
  region = "us-east-1"
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ REQUIREMENTS
# ---------------------------------------------------------------------------------------------------------------------
terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 4.0"
      configuration_aliases = []
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ DATA
# ---------------------------------------------------------------------------------------------------------------------
data "aws_region" "default" {}
data "aws_caller_identity" "current" {}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ LOCALS
# ---------------------------------------------------------------------------------------------------------------------
locals {}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ IAM - ORG ACCOUNT READER
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_iam_role" "ntc_org_account_reader" {
  name               = "ntc-org-account-reader"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.ntc_org_account_reader_trust.json
}

data "aws_iam_policy_document" "ntc_org_account_reader_trust" {
  statement {
    effect = "Allow"
    principals {
      type = "AWS"
      identifiers = [
        local.ntc_parameters["account-factory"]["core_accounts"]["aws-c2-security"]
      ]
    }
    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "ntc_org_account_reader" {
  statement {
    effect = "Allow"
    actions = [
      "account:GetAlternateContact",
      "account:GetContactInformation"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "ntc_org_account_reader" {
  name   = "ntc-org-account-reader"
  role   = aws_iam_role.ntc_org_account_reader.id
  policy = data.aws_iam_policy_document.ntc_org_account_reader.json
}