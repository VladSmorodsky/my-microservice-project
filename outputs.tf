output "s3_bucket_name" {
  description = "S3-bucket for states"
  value       = module.s3_backend.s3_bucket_name
}

output "dynamodb_table_name" {
  description = "DynamoDB table name for locked states"
  value       = module.s3_backend.dynamodb_table_name
}

output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = module.ecr.repository_url
}
