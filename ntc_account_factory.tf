# ---------------------------------------------------------------------------------------------------------------------
# ¦ NTC ACCOUNT FACTORY
# ---------------------------------------------------------------------------------------------------------------------
module "account_factory" {
  source = "github.com/nuvibit-terraform-collection/terraform-aws-ntc-account-factory?ref=beta"

  # baseline_scopes = [
  #   {
  #     scope_name = "workload_prod_euc1_use1"
  #     terraform_version = "1.3.9"
  #     aws_provider_version = "4.59.0"
  #     baseline_regions = ["us-east-1", "eu-central-1"]
  #     baseline_target_ou_path = "/root/workloads/prod"
  #     baseline_source_file_path = ""
  #   }
  # ]

  providers = {
    aws = aws.euc1
  }
}