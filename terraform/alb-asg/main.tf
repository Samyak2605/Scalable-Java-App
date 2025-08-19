# ALB and ASG Infrastructure Configuration

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

# ALB and ASG Module
module "alb_asg" {
  source = "../modules/alb-asg"

  # Network configuration
  region  = var.region
  vpc_id  = var.vpc_id
  subnets = var.subnets

  # ALB Security Group configuration
  ingress_alb_from_port   = var.ingress_alb_from_port
  ingress_alb_to_port     = var.ingress_alb_to_port
  ingress_alb_protocol    = var.ingress_alb_protocol
  ingress_alb_cidr_blocks = var.ingress_alb_cidr_blocks
  egress_alb_from_port    = var.egress_alb_from_port
  egress_alb_to_port      = var.egress_alb_to_port
  egress_alb_protocol     = var.egress_alb_protocol
  egress_alb_cidr_blocks  = var.egress_alb_cidr_blocks

  # ALB configuration
  internal          = var.internal
  loadbalancer_type = var.loadbalancer_type

  # Target Group configuration
  target_group_port                = var.target_group_port
  target_group_protocol            = var.target_group_protocol
  target_type                      = var.target_type
  load_balancing_algorithm         = var.load_balancing_algorithm
  health_check_path                = var.health_check_path
  health_check_port                = var.health_check_port
  health_check_protocol            = var.health_check_protocol
  health_check_interval            = var.health_check_interval
  health_check_timeout             = var.health_check_timeout
  health_check_healthy_threshold   = var.health_check_healthy_threshold
  health_check_unhealthy_threshold = var.health_check_unhealthy_threshold

  # Instance Security Group configuration
  ingress_asg_cidr_from_port = var.ingress_asg_cidr_from_port
  ingress_asg_cidr_to_port   = var.ingress_asg_cidr_to_port
  ingress_asg_cidr_protocol  = var.ingress_asg_cidr_protocol
  ingress_asg_cidr_blocks    = var.ingress_asg_cidr_blocks
  ingress_asg_sg_from_port   = var.ingress_asg_sg_from_port
  ingress_asg_sg_to_port     = var.ingress_asg_sg_to_port
  ingress_asg_sg_protocol    = var.ingress_asg_sg_protocol
  egress_asg_from_port       = var.egress_asg_from_port
  egress_asg_to_port         = var.egress_asg_to_port
  egress_asg_protocol        = var.egress_asg_protocol
  egress_asg_cidr_blocks     = var.egress_asg_cidr_blocks

  # ASG configuration
  max_size         = var.max_size
  min_size         = var.min_size
  desired_capacity = var.desired_capacity

  # Listener configuration
  listener_port     = var.listener_port
  listener_protocol = var.listener_protocol
  listener_type     = var.listener_type

  # Launch Template configuration
  ami_id               = var.ami_id
  instance_type        = var.instance_type
  key_name             = var.key_name
  user_data            = var.user_data
  public_access        = var.public_access
  instance_warmup_time = var.instance_warmup_time
  target_value         = var.target_value

  # Tags
  owner       = var.owner
  environment = var.environment
  cost_center = var.cost_center
  application = var.application
}
