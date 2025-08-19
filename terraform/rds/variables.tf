# RDS Configuration Variables

# Network Variables
variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "vpc_id" {
  description = "VPC ID where RDS will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for RDS subnet group"
  type        = list(string)
}

variable "multi_az" {
  description = "Enable Multi-AZ deployment"
  type        = bool
  default     = false
}

variable "publicly_accessible" {
  description = "Make RDS instance publicly accessible"
  type        = bool
  default     = true
}

# Database Variables
variable "db_engine" {
  description = "Database engine"
  type        = string
  default     = "mysql"
}

variable "db_storage_type" {
  description = "Storage type for RDS instance"
  type        = string
  default     = "gp2"
}

variable "db_username" {
  description = "Master username for RDS instance"
  type        = string
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_storage_size" {
  description = "Storage size in GB"
  type        = number
  default     = 20
}

variable "set_secret_manager_password" {
  description = "Use AWS Secrets Manager for password"
  type        = bool
  default     = true
}

variable "set_db_password" {
  description = "Set database password manually"
  type        = bool
  default     = false
}

variable "db_password" {
  description = "Master password for RDS instance"
  type        = string
  default     = "changeme123"
  sensitive   = true
}

# Security Group Variables
variable "ingress_from_port" {
  description = "Ingress from port"
  type        = number
  default     = 3306
}

variable "ingress_to_port" {
  description = "Ingress to port"
  type        = number
  default     = 3306
}

variable "ingress_protocol" {
  description = "Ingress protocol"
  type        = string
  default     = "tcp"
}

variable "ingress_cidr_blocks" {
  description = "Ingress CIDR blocks"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "egress_from_port" {
  description = "Egress from port"
  type        = number
  default     = 0
}

variable "egress_to_port" {
  description = "Egress to port"
  type        = number
  default     = 0
}

variable "egress_protocol" {
  description = "Egress protocol"
  type        = string
  default     = "-1"
}

variable "egress_cidr_blocks" {
  description = "Egress CIDR blocks"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# Backup Variables
variable "backup_retention_period" {
  description = "Backup retention period in days"
  type        = number
  default     = 7
}

variable "delete_automated_backups" {
  description = "Delete automated backups when instance is deleted"
  type        = bool
  default     = true
}

variable "copy_tags_to_snapshot" {
  description = "Copy tags to snapshots"
  type        = bool
  default     = true
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot when deleting"
  type        = bool
  default     = true
}

variable "apply_immediately" {
  description = "Apply changes immediately"
  type        = bool
  default     = true
}

# Parameter Store Variables
variable "parameter_store_secret_name" {
  description = "Parameter store path for RDS endpoint"
  type        = string
  default     = "/dev/petclinic/rds_endpoint"
}

variable "type" {
  description = "Parameter store type"
  type        = string
  default     = "String"
}

# Tag Variables
variable "owner" {
  description = "Owner tag"
  type        = string
  default     = "devops-team"
}

variable "environment" {
  description = "Environment tag"
  type        = string
  default     = "dev"
}

variable "cost_center" {
  description = "Cost center tag"
  type        = string
  default     = "engineering"
}

variable "application" {
  description = "Application tag"
  type        = string
  default     = "petclinic"
}
