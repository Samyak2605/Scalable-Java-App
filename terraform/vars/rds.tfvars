# Network Configuration
# Replace these with your actual VPC and subnet IDs
region              = "us-west-2"
vpc_id              = "vpc-12345678"  # Replace with your VPC ID
subnet_ids          = ["subnet-12345678", "subnet-87654321", "subnet-11111111"]  # Replace with your subnet IDs
multi_az            = false
publicly_accessible = true

# Database Configuration
db_engine                   = "mysql"
db_storage_type             = "gp2"
db_username                 = "petclinic"
db_instance_class           = "db.t3.micro"
db_storage_size             = 20
set_secret_manager_password = true
set_db_password             = false
db_password                 = "changeme123"

# Security Group Configuration
ingress_from_port   = 3306
ingress_to_port     = 3306
ingress_protocol    = "tcp"
ingress_cidr_blocks = ["0.0.0.0/0"]

egress_from_port   = 0
egress_to_port     = 0
egress_protocol    = "-1"
egress_cidr_blocks = ["0.0.0.0/0"]

# Backup Configuration
backup_retention_period  = 7
delete_automated_backups = true
copy_tags_to_snapshot    = true
skip_final_snapshot      = true
apply_immediately        = true

# Parameter Store Configuration
parameter_store_secret_name = "/dev/petclinic/rds_endpoint"
type                        = "String"

# Tag Configuration
owner       = "devops-team"
environment = "dev"
cost_center = "engineering"
application = "petclinic"
