# ---------------------------------------------------------------------------------------------------------------------
# ¦ DATA
# ---------------------------------------------------------------------------------------------------------------------
data "aws_region" "default" {}
data "aws_caller_identity" "current" {}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ OUTPUTS
# ---------------------------------------------------------------------------------------------------------------------
output "default_region" {
  description = "The default region name"
  value       = data.aws_region.default.name
}

output "account_id" {
  description = "The current account id"
  value       = data.aws_caller_identity.current.account_id
}