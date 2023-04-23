variable "org_cloudtrail_kms_alias" {
  type        = string
  description = "Alias for ClouTrail KMS key alias"

  validation {
    condition     = can(regex("^[a-zA-Z0-9\\/_-]{1,250}$"), var.org_cloudtrail_kms_alias)
    error_message = "\"org_cloudtrail_bucket_kms_alias\" must only contain ASCII letters (a-z, A-Z), numbers (0-9), slashes (/), underscores (_), or dashes (-)"
  }
}

variable "org_cloudtrail_bucket_name" {
  type        = string
  description = "Name of the bucket used to store CloudTrail logs (must exist)"

  validation {
    condition     = can(regex("(?!(^xn--|.+-s3alias$))^[a-z0-9][a-z0-9-]{1,61}[a-z0-9]$", var.org_cloudtrail_bucket_name))
    error_message = "\"org_cloudtrail_bucket_name\" needs to be a valid s3 bucket name."
  }
}
