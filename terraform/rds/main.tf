# RDS Infrastructure Configuration

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure AWS Provider
provider "aws" {
  region = var.region
  
  default_tags {
    tags = {
      Project     = "Pet Clinic"
      Owner       = var.owner
      Environment = var.environment
      CostCenter  = var.cost_center
      Application = var.application
      ManagedBy   = "Terraform"
    }
  }
}

# RDS Module
module "rds" {
  source = "../modules/rds"

  # Network configuration
  region                  = var.region
  vpc_id                  = var.vpc_id
  subnet_ids              = var.subnet_ids
  multi_az                = var.multi_az
  publicly_accessible     = var.publicly_accessible

  # Database configuration
  db_engine                   = var.db_engine
  db_storage_type             = var.db_storage_type
  db_username                 = var.db_username
  db_instance_class           = var.db_instance_class
  db_storage_size             = var.db_storage_size
  set_secret_manager_password = var.set_secret_manager_password
  set_db_password             = var.set_db_password
  db_password                 = var.db_password

  # Security group configuration
  ingress_from_port   = var.ingress_from_port
  ingress_to_port     = var.ingress_to_port
  ingress_protocol    = var.ingress_protocol
  ingress_cidr_blocks = var.ingress_cidr_blocks
  egress_from_port    = var.egress_from_port
  egress_to_port      = var.egress_to_port
  egress_protocol     = var.egress_protocol
  egress_cidr_blocks  = var.egress_cidr_blocks

  # Backup configuration
  backup_retention_period  = var.backup_retention_period
  delete_automated_backups = var.delete_automated_backups
  copy_tags_to_snapshot    = var.copy_tags_to_snapshot
  skip_final_snapshot      = var.skip_final_snapshot
  apply_immediately        = var.apply_immediately

  # Parameter store configuration
  parameter_store_secret_name = var.parameter_store_secret_name
  type                        = var.type

  # Tags
  owner       = var.owner
  environment = var.environment
  cost_center = var.cost_center
  application = var.application
}
