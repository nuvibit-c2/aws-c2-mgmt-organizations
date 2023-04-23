# ---------------------------------------------------------------------------------------------------------------------
# ¦ DATA
# ---------------------------------------------------------------------------------------------------------------------

data "aws_caller_identity" "current" {}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ KMS KEY
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_kms_key" "org_cloudtrail_kms" {
  description             = "Encryption key for Organization Cloudtrail"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.org_cloudtrail_kms.json
}

data "aws_iam_policy_document" "org_cloudtrail_kms" {
  # enable IAM access
  statement {
    sid    = "Enable IAM User Permissions"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }

    actions   = ["kms:*"]
    resources = ["*"]
  }

  # allow access for organization cloudtrail
  statement {
    sid       = "Allow CloudTrail to encrypt logs"
    effect    = "Allow"
    actions   = ["kms:GenerateDataKey"]
    resources = ["*"]

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "kms:EncryptionContext:aws:cloudtrail:arn"
      values = [
        format(
          "arn:aws:cloudtrail:*:%s:trail/%s",
          data.aws_caller_identity.current.account_id,
          var.org_cloudtrail_name
        )
      ]
    }
  }

  statement {
    sid       = "Allow CloudTrail to describe key"
    effect    = "Allow"
    actions   = ["kms:DescribeKey"]
    resources = ["*"]

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
  }
}

resource "aws_kms_alias" "org_cloudtrail_kms" {
  name          = format("alias/%s", var.org_cloudtrail_kms_alias
  target_key_id = aws_kms_key.org_cloudtrail_bucket_kms.key_id
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ ORGANIZATION CLOUDTRAIL
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_cloudtrail" "org_cloudtrail" {
  name           = var.org_cloudtrail_name
  s3_bucket_name = var.org_cloudtrail_bucket_name
  kms_key_id     = aws_kms_key.org_cloudtrail_kms.arn

  is_organization_trail = true
  include_global_service_events = true
  is_multi_region_trail = true
}
