# RDS Module for Pet Clinic Application

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Data source for availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# Security Group for RDS
resource "aws_security_group" "rds_sg" {
  name_prefix = "${var.application}-rds-sg"
  vpc_id      = var.vpc_id
  description = "Security group for RDS MySQL instance"

  ingress {
    from_port   = var.ingress_from_port
    to_port     = var.ingress_to_port
    protocol    = var.ingress_protocol
    cidr_blocks = var.ingress_cidr_blocks
    description = "MySQL access"
  }

  egress {
    from_port   = var.egress_from_port
    to_port     = var.egress_to_port
    protocol    = var.egress_protocol
    cidr_blocks = var.egress_cidr_blocks
    description = "All outbound traffic"
  }

  tags = {
    Name        = "${var.application}-rds-sg"
    Owner       = var.owner
    Environment = var.environment
    CostCenter  = var.cost_center
    Application = var.application
  }
}

# DB Subnet Group
resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "${var.application}-db-subnet-group"
  subnet_ids = var.subnet_ids

  tags = {
    Name        = "${var.application}-db-subnet-group"
    Owner       = var.owner
    Environment = var.environment
    CostCenter  = var.cost_center
    Application = var.application
  }
}

# Random password for RDS
resource "random_password" "rds_password" {
  count   = var.set_secret_manager_password ? 1 : 0
  length  = 16
  special = true
}

# AWS Secrets Manager secret for RDS credentials
resource "aws_secretsmanager_secret" "rds_credentials" {
  count                   = var.set_secret_manager_password ? 1 : 0
  name                    = "${var.application}-rds-credentials-${random_id.secret_suffix[0].hex}"
  description             = "RDS credentials for ${var.application}"
  recovery_window_in_days = 0

  tags = {
    Name        = var.environment
    Owner       = var.owner
    Environment = var.environment
    CostCenter  = var.cost_center
    Application = var.application
  }
}

# Random ID for secret name uniqueness
resource "random_id" "secret_suffix" {
  count       = var.set_secret_manager_password ? 1 : 0
  byte_length = 4
}

# Secret version with RDS credentials
resource "aws_secretsmanager_secret_version" "rds_credentials" {
  count     = var.set_secret_manager_password ? 1 : 0
  secret_id = aws_secretsmanager_secret.rds_credentials[0].id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.rds_password[0].result
  })
}

# RDS Instance
resource "aws_db_instance" "rds_instance" {
  identifier = "${var.application}-rds-instance"

  # Engine configuration
  engine         = var.db_engine
  engine_version = var.db_engine_version
  instance_class = var.db_instance_class

  # Storage configuration
  allocated_storage     = var.db_storage_size
  max_allocated_storage = var.db_storage_size * 2
  storage_type          = var.db_storage_type
  storage_encrypted     = true

  # Database configuration
  db_name  = var.db_name
  username = var.db_username
  password = var.set_secret_manager_password ? random_password.rds_password[0].result : var.db_password

  # Network configuration
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  publicly_accessible    = var.publicly_accessible
  multi_az               = var.multi_az

  # Backup configuration
  backup_retention_period   = var.backup_retention_period
  backup_window             = "03:00-04:00"
  maintenance_window        = "sun:04:00-sun:05:00"
  delete_automated_backups  = var.delete_automated_backups
  copy_tags_to_snapshot     = var.copy_tags_to_snapshot
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.application}-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"

  # Performance configuration
  performance_insights_enabled = false
  monitoring_interval          = 0

  # Update configuration
  apply_immediately   = var.apply_immediately
  deletion_protection = false

  # Parameter group
  parameter_group_name = "default.mysql8.0"

  tags = {
    Name        = "${var.application}-rds-instance"
    Owner       = var.owner
    Environment = var.environment
    CostCenter  = var.cost_center
    Application = var.application
  }

  depends_on = [
    aws_db_subnet_group.rds_subnet_group,
    aws_security_group.rds_sg
  ]
}

# Store RDS endpoint in Parameter Store
resource "aws_ssm_parameter" "rds_endpoint" {
  name  = var.parameter_store_secret_name
  type  = var.type
  value = aws_db_instance.rds_instance.endpoint

  tags = {
    Name        = "${var.application}-rds-endpoint"
    Owner       = var.owner
    Environment = var.environment
    CostCenter  = var.cost_center
    Application = var.application
  }
}
