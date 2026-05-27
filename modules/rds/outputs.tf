# modules/rds/outputs.tf

output "primary_endpoint" {
  value       = aws_db_instance.primary.endpoint
  description = "RDS Primary 엔드포인트 (쓰기)"
}

output "replica_endpoint" {
  value       = aws_db_instance.replica.endpoint
  description = "RDS Replica 엔드포인트 (읽기)"
}

output "security_group_id" {
  value = aws_security_group.rds.id
}

output "db_name" {
  value = aws_db_instance.primary.db_name
}

output "primary_instance_id" {
  value       = aws_db_instance.primary.id
  description = "Primary RDS Instance ID"
}