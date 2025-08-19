# RDS Module Outputs

output "rds_instance_id" {
  description = "The ID of the RDS instance"
  value       = aws_db_instance.rds_instance.id
}

output "rds_instance_endpoint" {
  description = "The RDS instance endpoint"
  value       = aws_db_instance.rds_instance.endpoint
}

output "rds_instance_port" {
  description = "The RDS instance port"
  value       = aws_db_instance.rds_instance.port
}

output "rds_instance_arn" {
  description = "The ARN of the RDS instance"
  value       = aws_db_instance.rds_instance.arn
}

output "rds_instance_status" {
  description = "The RDS instance status"
  value       = aws_db_instance.rds_instance.status
}

output "rds_instance_address" {
  description = "The RDS instance address"
  value       = aws_db_instance.rds_instance.address
}

output "rds_instance_hosted_zone_id" {
  description = "The canonical hosted zone ID of the DB instance"
  value       = aws_db_instance.rds_instance.hosted_zone_id
}

output "rds_instance_resource_id" {
  description = "The RDS Resource ID of this instance"
  value       = aws_db_instance.rds_instance.resource_id
}

output "rds_instance_engine" {
  description = "The database engine"
  value       = aws_db_instance.rds_instance.engine
}

output "rds_instance_engine_version" {
  description = "The running version of the database"
  value       = aws_db_instance.rds_instance.engine_version_actual
}

output "rds_instance_class" {
  description = "The RDS instance class"
  value       = aws_db_instance.rds_instance.instance_class
}

output "rds_instance_username" {
  description = "The master username for the RDS instance"
  value       = aws_db_instance.rds_instance.username
  sensitive   = true
}

output "rds_db_name" {
  description = "The database name"
  value       = aws_db_instance.rds_instance.db_name
}

output "rds_subnet_group_id" {
  description = "The ID of the DB subnet group"
  value       = aws_db_subnet_group.rds_subnet_group.id
}

output "rds_subnet_group_arn" {
  description = "The ARN of the DB subnet group"
  value       = aws_db_subnet_group.rds_subnet_group.arn
}

output "rds_security_group_id" {
  description = "The ID of the RDS security group"
  value       = aws_security_group.rds_sg.id
}

output "rds_security_group_arn" {
  description = "The ARN of the RDS security group"
  value       = aws_security_group.rds_sg.arn
}

output "secrets_manager_secret_arn" {
  description = "The ARN of the Secrets Manager secret"
  value       = var.set_secret_manager_password ? aws_secretsmanager_secret.rds_credentials[0].arn : null
}

output "secrets_manager_secret_id" {
  description = "The ID of the Secrets Manager secret"
  value       = var.set_secret_manager_password ? aws_secretsmanager_secret.rds_credentials[0].id : null
}

output "ssm_parameter_name" {
  description = "The name of the SSM parameter storing the RDS endpoint"
  value       = aws_ssm_parameter.rds_endpoint.name
}

output "ssm_parameter_arn" {
  description = "The ARN of the SSM parameter storing the RDS endpoint"
  value       = aws_ssm_parameter.rds_endpoint.arn
}
