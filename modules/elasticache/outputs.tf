# modules/elasticache/outputs.tf

output "redis_endpoint" {
  value       = aws_elasticache_cluster.this.cache_nodes[0].address
  description = "Redis 엔드포인트"
}

output "redis_port" {
  value       = aws_elasticache_cluster.this.port
  description = "Redis 포트"
}

output "security_group_id" {
  value       = aws_security_group.redis.id
  description = "Redis SG ID"
}
