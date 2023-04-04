# ---------------------------------------------------------------------------------------------------------------------
# ¦ CROSS ACCOUNT TESTING
# ---------------------------------------------------------------------------------------------------------------------
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

provider "aws" {
  alias  = "aws-c2-security"
  region = "eu-central-1"
  assume_role {
    role_arn = "arn:aws:iam::769269768678:role/OrganizationAccountAccessRole"
  }
}