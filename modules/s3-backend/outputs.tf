output "s3_bucket_name" {
  description = "S3 bucket state name"
  value       = aws_s3_bucket.terraform_state.bucket
}

output "dynamodb_table_name" {
  description = "DynamoDB Locked State Table"
  value       = aws_dynamodb_table.terraform_locks.name
}
