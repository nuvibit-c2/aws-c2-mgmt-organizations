variable "bucket_name" {
  description = "Name of the S3 bucket where core parameters will be stored."
  type        = string
}

variable "custom_bucket_policy_json" {
  description = "Custom S3 bucket policy as JSON string. This will overwrite the default bucket policy."
  type        = string
  default     = ""

  validation {
    condition     = length(var.custom_bucket_policy_json) == 0 || can(jsondecode(var.custom_bucket_policy_json))
    error_message = "\"custom_bucket_policy_json\" must be valid JSON."
  }
}

variable "core_parameters_map" {
  description = "Core parameters map."
  type        = any
  default     = {}
}

variable "org_id" {
  description = "Organization Id to limit bucket access to organization members."
  type        = string
  default     = ""
}

variable "tags" {
  description = "A map of tags to add to all resources."
  type        = map(string)
  default     = {}
}