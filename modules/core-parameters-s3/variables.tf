variable "bucket_name" {
  description = "Name of the S3 bucket where core parameters will be stored."
  type        = string
}

variable "custom_bucket_read_policy_json" {
  description = "Custom S3 bucket read policy as JSON string. This will overwrite the default bucket policy."
  type        = string
  default     = ""

  validation {
    condition     = length(var.custom_bucket_read_policy_json) == 0 || can(jsondecode(var.custom_bucket_read_policy_json))
    error_message = "\"custom_bucket_read_policy_json\" must be valid JSON."
  }
}

variable "parameter_nodes" {
  description = "List of parameter nodes. Nodes can be merged into a single parameter map. A node owner (usually a core account) is allowed to manage parameters in his node."
  type = list(object({
    node_name = string
    node_owner_account_id = string
  }))
  default     = []

  validation {
    condition     = length(var.parameter_nodes) == length(distinct([for p in var.parameter_nodes : p.node_name]))
    error_message = "\"node_name\" must be unique in list of \"parameter_nodes\"."
  }

  validation {
    condition     = alltrue([
      for node in var.parameter_nodes : can(regex("^[a-z0-1_]+$", lower(node.node_name)))
    ])
    error_message = "Allowed characters for \"parameter_nodes.node_name\" are letters, numbers and _."
  }

  validation {
    condition     = alltrue([
      for node in var.parameter_nodes : can(regex("^[0-9]{12}$", lower(node.node_owner_account_id)))
    ])
    error_message = "\"parameter_nodes.node_owner_account_id\" must be valid account id."
  }
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