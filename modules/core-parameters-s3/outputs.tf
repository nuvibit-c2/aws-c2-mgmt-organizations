output "bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.core_parameters.arn
}

output "bucket_id" {
  description = "ID of the S3 bucket"
  value       = aws_s3_bucket.core_parameters.id
}