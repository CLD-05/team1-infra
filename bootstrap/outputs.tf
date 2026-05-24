# bootstrap/outputs.tf

output "s3_bucket_name" {
  value       = aws_s3_bucket.terraform_state.id
  description = "Terraform state S3 버킷 이름"
}

output "dynamodb_table_name" {
  value       = aws_dynamodb_table.terraform_lock.name
  description = "Terraform lock DynamoDB 테이블 이름"
}
