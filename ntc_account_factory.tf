# ---------------------------------------------------------------------------------------------------------------------
# ¦ NTC ACCOUNT FACTORY
# ---------------------------------------------------------------------------------------------------------------------
module "account_factory" {
  source = "github.com/nuvibit-terraform-collection/terraform-aws-ntc-account-factory?ref=beta"

  baseline_bucket_name = "aws-c2-ntc-account-factory-baseline"
  baseline_scopes = [
    {
      scope_name           = "workloads_prod"
      terraform_version    = "1.3.9"
      aws_provider_version = "4.59.0"
      decommission         = false
      terraform_baseline_contents = [
        file("${path.module}/baseline-examples/baseline_data.tf")
      ]
      regions = ["us-east-1", "eu-central-1"]
      # decide which AWS accounts should be added to this baseline scope
      target_ou_paths = [
        "/root/workloads/prod"
      ]
      target_account_names = [
        # "aws-c2-0001",
        # "aws-c2-0002"
      ]
      target_account_tags = [
        # {
        #   key = "AccountType"
        #   value = "core"
        # }
      ]
    }
  ]

  providers = {
    aws = aws.euc1
  }
}