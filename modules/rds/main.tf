# modules/rds/main.tf
#
# 생성 리소스:
#   - aws_db_subnet_group  : RDS 서브넷 그룹 (Isolated Subnet)
#   - aws_security_group   : RDS SG (EKS 노드에서만 접근 허용)
#   - aws_db_instance      : RDS MySQL (Single-AZ → Multi-AZ는 Day6에 전환)
#   - aws_db_instance      : RDS Read Replica

resource "aws_db_subnet_group" "this" {
  name       = "${var.project}-rds-subnet-group"
  subnet_ids = var.isolated_subnet_ids

  tags = {
    Name      = "${var.project}-rds-subnet-group"
    ManagedBy = "terraform"
  }
}

# RDS 보안그룹 (EKS 노드 SG에서만 3306 허용)
resource "aws_security_group" "rds" {
  name        = "${var.project}-rds-sg"
  description = "RDS Security Group"
  vpc_id      = var.vpc_id

  ingress {
    description     = "MySQL from EKS nodes"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [var.node_security_group_id]
  }

  ingress {
    description     = "MySQL from Bastion"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [var.bastion_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project}-rds-sg"
  }
}

# KMS Key (RDS 암호화용)
resource "aws_kms_key" "rds" {
  description             = "RDS encryption key"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Name = "${var.project}-rds-kms"
  }
}

# RDS Primary (Single-AZ → Day6에 Multi-AZ 전환)
resource "aws_db_instance" "primary" {
  identifier        = "${var.project}-rds-primary"
  engine            = "mysql"
  engine_version    = "8.0"
  instance_class    = var.instance_class
  allocated_storage = 20
  storage_type      = "gp3"
  storage_encrypted = true
  kms_key_id        = aws_kms_key.rds.arn

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  # Day 1~5: Single-AZ
  # Day 6: Multi-AZ 전환
  multi_az            = var.multi_az
  publicly_accessible = false
  skip_final_snapshot = true
  deletion_protection = false

  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "Mon:04:00-Mon:05:00"

  tags = {
    Name      = "${var.project}-rds-primary"
    ManagedBy = "terraform"
  }
}

# RDS Read Replica
resource "aws_db_instance" "replica" {
  identifier          = "${var.project}-rds-replica"
  replicate_source_db = aws_db_instance.primary.identifier
  availability_zone   = var.replica_az      # replica az 지정
  instance_class      = var.instance_class
  storage_encrypted   = true
  kms_key_id          = aws_kms_key.rds.arn

  publicly_accessible    = false
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.rds.id]

  tags = {
    Name      = "${var.project}-rds-replica"
    ManagedBy = "terraform"
  }
}
