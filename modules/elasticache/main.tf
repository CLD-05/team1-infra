# modules/elasticache/main.tf
#
# 생성 리소스:
#   - aws_elasticache_subnet_group : ElastiCache 서브넷 그룹 (Isolated Subnet)
#   - aws_security_group           : Redis SG (EKS 노드에서만 6379 허용)
#   - aws_elasticache_cluster      : Redis 클러스터

resource "aws_elasticache_subnet_group" "this" {
  name       = "${var.project}-redis-subnet-group"
  subnet_ids = var.isolated_subnet_ids

  tags = {
    Name      = "${var.project}-redis-subnet-group"
    ManagedBy = "terraform"
  }
}

# Redis 보안그룹 (EKS 노드 SG에서만 6379 허용)
resource "aws_security_group" "redis" {
  name        = "${var.project}-redis-sg"
  description = "ElastiCache Redis Security Group"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Redis from EKS nodes"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [var.node_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project}-redis-sg"
  }
}

# ElastiCache Redis
resource "aws_elasticache_cluster" "this" {
  cluster_id           = "${var.project}-redis"
  engine               = "redis"
  engine_version       = "7.0"
  node_type            = var.node_type
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  port                 = 6379

  subnet_group_name  = aws_elasticache_subnet_group.this.name
  security_group_ids = [aws_security_group.redis.id]

  # 스냅샷 (백업)
  snapshot_retention_limit = 1
  snapshot_window          = "03:00-04:00"

  tags = {
    Name      = "${var.project}-redis"
    ManagedBy = "terraform"
  }
}
