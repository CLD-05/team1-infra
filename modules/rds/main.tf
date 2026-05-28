# modules/rds/main.tf

resource "aws_db_subnet_group" "this" {
  name       = "${var.project}-rds-subnet-group"
  subnet_ids = var.isolated_subnet_ids

  tags = {
    Name      = "${var.project}-rds-subnet-group"
    ManagedBy = "terraform"
  }
}

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

resource "aws_kms_key" "rds" {
  description             = "RDS encryption key"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Name = "${var.project}-rds-kms"
  }
}

resource "aws_db_instance" "primary" {
  identifier        = "${var.project}-rds-primary"
  engine            = "mysql"
  engine_version    = "8.0"
  instance_class    = var.instance_class
  availability_zone = var.multi_az ? null : var.primary_az
  allocated_storage = 20
  storage_type      = "gp3"
  storage_encrypted = true
  kms_key_id        = aws_kms_key.rds.arn

  db_name  = var.db_name
  username = var.db_username # SSM에서 넘겨받음
  password = var.db_password # SSM에서 넘겨받음

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.rds.id]

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

resource "aws_db_instance" "replica" {
  identifier          = "${var.project}-rds-replica"
  replicate_source_db = aws_db_instance.primary.identifier
  availability_zone   = var.multi_az ? null : var.replica_az
  instance_class      = var.instance_class
  storage_encrypted   = true
  kms_key_id          = aws_kms_key.rds.arn

  publicly_accessible    = false
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.rds.id]

  depends_on = [aws_db_instance.primary]

  tags = {
    Name      = "${var.project}-rds-replica"
    ManagedBy = "terraform"
  }
}
