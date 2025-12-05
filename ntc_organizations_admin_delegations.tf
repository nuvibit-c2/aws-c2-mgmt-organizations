locals {
  # some services like 'aws config' and 'iam access analyzer' are delegated once and not for each region
  global_delegated_administrators = [
    {
      service_principal = "config.${local.current_partition_dns_suffix}"
      admin_account_id  = local.security_account_id
    },
    {
      service_principal = "access-analyzer.${local.current_partition_dns_suffix}"
      admin_account_id  = local.security_account_id
    },
    {
      service_principal = "backup.${local.current_partition_dns_suffix}"
      admin_account_id  = local.backup_account_id
    },
  ]

  # some services like amazon guardduty need to be delegated for each region
  regional_delegated_administrators = [
    {
      service_principal = "securityhub.${local.current_partition_dns_suffix}"
      admin_account_id  = local.security_account_id
    },
    {
      service_principal = "guardduty.${local.current_partition_dns_suffix}"
      admin_account_id  = local.security_account_id
    },
    {
      service_principal = "inspector2.${local.current_partition_dns_suffix}"
      admin_account_id  = local.security_account_id
    }
  ]
}

# organizations integration of iam access analyzer requires a service linked role in org management account
resource "aws_iam_service_linked_role" "access_analyzer" {
  aws_service_name = "access-analyzer.${local.current_partition_dns_suffix}"
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ NTC ORGANIZATIONS - ADMIN DELEGATIONS
# ---------------------------------------------------------------------------------------------------------------------
module "ntc_delegated_admins_euc1" {
  source = "github.com/nuvibit-terraform-collection/terraform-aws-ntc-organizations//modules/regional-admin-delegations?ref=1.5.0"

  delegated_administrators = concat(local.global_delegated_administrators, local.regional_delegated_administrators)

  providers = {
    aws = aws.euc1
  }
}

module "ntc_delegated_admins_euc2" {
  source = "github.com/nuvibit-terraform-collection/terraform-aws-ntc-organizations//modules/regional-admin-delegations?ref=1.5.0"

  delegated_administrators = local.regional_delegated_administrators

  providers = {
    aws = aws.euc2
  }
}

module "ntc_delegated_admins_use1" {
  source = "github.com/nuvibit-terraform-collection/terraform-aws-ntc-organizations//modules/regional-admin-delegations?ref=1.5.0"

  delegated_administrators = local.regional_delegated_administrators

  providers = {
    aws = aws.use1
  }
}
