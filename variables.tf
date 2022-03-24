variable "resource_tags" {
  description = "A map of tags to assign to the resources in this module."
  type        = map(string)
  default     = {}
}

variable "resource_name_suffix" {
  description = "Alphanumeric suffix for all the resource names in this module."
  type        = string
  default     = ""

  validation {
    condition     = var.resource_name_suffix == "" ? true : can(regex("[[:alnum:]]", var.resource_name_suffix))
    error_message = "Value must be alphanumeric."
  }
}

variable "resource_name_prefix" {
  description = "Alphanumeric prefix for all the resource names in this module."
  type        = string
  default     = ""

  validation {
    condition     = var.resource_name_prefix == "" ? true : can(regex("[[:alnum:]]", var.resource_name_prefix))
    error_message = "Value must be alphanumeric."
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ MAIN
# ---------------------------------------------------------------------------------------------------------------------
