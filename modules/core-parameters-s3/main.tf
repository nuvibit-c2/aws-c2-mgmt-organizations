# ---------------------------------------------------------------------------------------------------------------------
# ¦ REQUIREMENTS
# ---------------------------------------------------------------------------------------------------------------------
terraform {
  required_version = ">= 1.0.0"

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
data "aws_organizations_organization" "current" {
  # get organization id only when no custom bucket policy and org id is provided
  count = alltrue([
    length(var.org_id) < 1,
    length(var.custom_bucket_read_policy_json) < 1
  ]) ? 1 : 0
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ LOCALS
# ---------------------------------------------------------------------------------------------------------------------
locals {
  org_id = try(data.aws_organizations_organization.current[0].id, var.org_id)
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ IAM DEFAULT BUCKET POLICY
# ---------------------------------------------------------------------------------------------------------------------
data "aws_iam_policy_document" "read_access_for_organization" {
  statement {
    sid    = "AllowReadAccessOrganization"
    effect = "Allow"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions = [
      "s3:GetObject",
    ]
    resources = [
      "${aws_s3_bucket.core_parameters.arn}/*",
    ]
    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalOrgID"
      values   = [local.org_id]
    }
  }
}

data "aws_iam_policy_document" "write_access_for_node_owners" {
  for_each = {
    for node in var.parameter_nodes : node.node_name => node
  }

  statement {
    sid    = "AllowWriteAccessNodeOwners"
    effect = "Allow"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions = [
      "s3:PutObject",
    ]
    resources = [
      "${aws_s3_bucket.core_parameters.arn}/${each.value.account_id}/*",
    ]
    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalOrgID"
      values   = [local.org_id]
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ S3 BUCKET
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_s3_bucket" "core_parameters" {
  bucket = var.bucket_name
}

resource "aws_s3_bucket_versioning" "core_parameters" {
  bucket = aws_s3_bucket.core_parameters.bucket
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "core_parameters" {
  bucket = aws_s3_bucket.core_parameters.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "read_access_for_organization" {
  bucket = aws_s3_bucket.core_parameters.id
  policy = length(var.custom_bucket_read_policy_json) > 0 ? var.custom_bucket_read_policy_json : data.aws_iam_policy_document.read_access_for_organization.json
}

resource "aws_s3_bucket_policy" "write_access_for_node_ownerss" {
  for_each = {
    for node in var.parameter_nodes : node.node_name => node
  }

  bucket = aws_s3_bucket.core_parameters.id
  policy = data.aws_iam_policy_document.write_access_for_node_ownerss[each.key].json
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ S3 OBJECTS
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_s3_object" "parameter_nodes" {
  for_each = {
    for node in var.parameter_nodes : node.node_name => node
  }

  bucket       = aws_s3_bucket.core_parameters.id
  key          = "${each.key}/parameters.json"
  content      = "{}"
  content_type = "application/json"

  lifecycle {
    ignore_changes = [
      # content is managed by node owners
      content,
    ]
  }
}
