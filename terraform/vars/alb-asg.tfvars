# Network Configuration
# Replace these with your actual VPC and subnet IDs
region  = "us-west-2"
vpc_id  = "vpc-12345678"  # Replace with your VPC ID
subnets = ["subnet-12345678", "subnet-87654321", "subnet-11111111"]  # Replace with your subnet IDs

# ALB Security Group Configuration
ingress_alb_from_port   = 80
ingress_alb_to_port     = 80
ingress_alb_protocol    = "tcp"
ingress_alb_cidr_blocks = ["0.0.0.0/0"]
egress_alb_from_port    = 0
egress_alb_to_port      = 0
egress_alb_protocol     = "-1"
egress_alb_cidr_blocks  = ["0.0.0.0/0"]

# ALB Configuration
internal          = false
loadbalancer_type = "application"

# Target Group Configuration
target_group_port                = 8080
target_group_protocol            = "HTTP"
target_type                      = "instance"
load_balancing_algorithm         = "round_robin"
health_check_path                = "/"
health_check_port                = 8080
health_check_protocol            = "HTTP"
health_check_interval            = 30
health_check_timeout             = 5
health_check_healthy_threshold   = 2
health_check_unhealthy_threshold = 2

# Instance Security Group Configuration
ingress_asg_cidr_from_port = 22
ingress_asg_cidr_to_port   = 22
ingress_asg_cidr_protocol  = "tcp"
ingress_asg_cidr_blocks    = ["0.0.0.0/0"]
ingress_asg_sg_from_port   = 8080
ingress_asg_sg_to_port     = 8080
ingress_asg_sg_protocol    = "tcp"
egress_asg_from_port       = 0
egress_asg_to_port         = 0
egress_asg_protocol        = "-1"
egress_asg_cidr_blocks     = ["0.0.0.0/0"]

# Auto Scaling Group Configuration
max_size         = 3
min_size         = 1
desired_capacity = 2

# Listener Configuration
listener_port     = 80
listener_protocol = "HTTP"
listener_type     = "forward"

# Launch Template Configuration
ami_id        = "ami-0123456789abcdef0"  # Replace with your Packer-built AMI ID
instance_type = "t2.medium"
key_name      = "your-key-pair"  # Replace with your EC2 key pair name
user_data     = <<-EOF
#!/bin/bash
bash /home/ubuntu/start.sh
EOF
public_access        = true
instance_warmup_time = 30
target_value         = 50

# Tag Configuration
owner       = "devops-team"
environment = "dev"
cost_center = "engineering"
application = "petclinic"
