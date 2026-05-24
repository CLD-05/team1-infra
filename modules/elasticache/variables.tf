# modules/elasticache/variables.tf

variable "project" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "isolated_subnet_ids" {
  type        = list(string)
  description = "ElastiCache 배치할 Isolated 서브넷 ID 목록"
}

variable "node_security_group_id" {
  type        = string
  description = "EKS 노드 SG ID (Redis 접근 허용)"
}

variable "node_type" {
  type        = string
  default     = "cache.t3.micro"
  description = "ElastiCache 노드 타입"
}
