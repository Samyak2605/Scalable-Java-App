# Network Variables
variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "vpc_id" {
  description = "VPC ID where resources will be deployed"
  type        = string
}

variable "subnets" {
  description = "List of subnet IDs for ALB and ASG"
  type        = list(string)
}

# ALB Security Group Variables
variable "ingress_alb_from_port" {
  description = "ALB ingress from port"
  type        = number
  default     = 80
}

variable "ingress_alb_to_port" {
  description = "ALB ingress to port"
  type        = number
  default     = 80
}

variable "ingress_alb_protocol" {
  description = "ALB ingress protocol"
  type        = string
  default     = "tcp"
}

variable "ingress_alb_cidr_blocks" {
  description = "ALB ingress CIDR blocks"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "egress_alb_from_port" {
  description = "ALB egress from port"
  type        = number
  default     = 0
}

variable "egress_alb_to_port" {
  description = "ALB egress to port"
  type        = number
  default     = 0
}

variable "egress_alb_protocol" {
  description = "ALB egress protocol"
  type        = string
  default     = "-1"
}

variable "egress_alb_cidr_blocks" {
  description = "ALB egress CIDR blocks"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# ALB Variables
variable "internal" {
  description = "Make ALB internal"
  type        = bool
  default     = false
}

variable "loadbalancer_type" {
  description = "Type of load balancer"
  type        = string
  default     = "application"
}

# Target Group Variables
variable "target_group_port" {
  description = "Target group port"
  type        = number
  default     = 8080
}

variable "target_group_protocol" {
  description = "Target group protocol"
  type        = string
  default     = "HTTP"
}

variable "target_type" {
  description = "Target type"
  type        = string
  default     = "instance"
}

variable "load_balancing_algorithm" {
  description = "Load balancing algorithm"
  type        = string
  default     = "round_robin"
}

variable "health_check_path" {
  description = "Health check path"
  type        = string
  default     = "/"
}

variable "health_check_port" {
  description = "Health check port"
  type        = number
  default     = 8080
}

variable "health_check_protocol" {
  description = "Health check protocol"
  type        = string
  default     = "HTTP"
}

variable "health_check_interval" {
  description = "Health check interval in seconds"
  type        = number
  default     = 30
}

variable "health_check_timeout" {
  description = "Health check timeout in seconds"
  type        = number
  default     = 5
}

variable "health_check_healthy_threshold" {
  description = "Health check healthy threshold"
  type        = number
  default     = 2
}

variable "health_check_unhealthy_threshold" {
  description = "Health check unhealthy threshold"
  type        = number
  default     = 2
}

# Instance Security Group Variables
variable "ingress_asg_cidr_from_port" {
  description = "ASG CIDR ingress from port (SSH)"
  type        = number
  default     = 22
}

variable "ingress_asg_cidr_to_port" {
  description = "ASG CIDR ingress to port (SSH)"
  type        = number
  default     = 22
}

variable "ingress_asg_cidr_protocol" {
  description = "ASG CIDR ingress protocol"
  type        = string
  default     = "tcp"
}

variable "ingress_asg_cidr_blocks" {
  description = "ASG CIDR ingress blocks"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "ingress_asg_sg_from_port" {
  description = "ASG security group ingress from port (app)"
  type        = number
  default     = 8080
}

variable "ingress_asg_sg_to_port" {
  description = "ASG security group ingress to port (app)"
  type        = number
  default     = 8080
}

variable "ingress_asg_sg_protocol" {
  description = "ASG security group ingress protocol"
  type        = string
  default     = "tcp"
}

variable "egress_asg_from_port" {
  description = "ASG egress from port"
  type        = number
  default     = 0
}

variable "egress_asg_to_port" {
  description = "ASG egress to port"
  type        = number
  default     = 0
}

variable "egress_asg_protocol" {
  description = "ASG egress protocol"
  type        = string
  default     = "-1"
}

variable "egress_asg_cidr_blocks" {
  description = "ASG egress CIDR blocks"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# Auto Scaling Group Variables
variable "max_size" {
  description = "Maximum size of ASG"
  type        = number
  default     = 3
}

variable "min_size" {
  description = "Minimum size of ASG"
  type        = number
  default     = 1
}

variable "desired_capacity" {
  description = "Desired capacity of ASG"
  type        = number
  default     = 2
}

# Listener Variables
variable "listener_port" {
  description = "Listener port"
  type        = number
  default     = 80
}

variable "listener_protocol" {
  description = "Listener protocol"
  type        = string
  default     = "HTTP"
}

variable "listener_type" {
  description = "Listener action type"
  type        = string
  default     = "forward"
}

# Launch Template Variables
variable "ami_id" {
  description = "AMI ID for launch template"
  type        = string
}

variable "instance_type" {
  description = "Instance type for launch template"
  type        = string
  default     = "t2.medium"
}

variable "key_name" {
  description = "Key pair name for instances"
  type        = string
}

variable "user_data" {
  description = "User data script for instances"
  type        = string
  default     = ""
}

variable "public_access" {
  description = "Enable public IP for instances"
  type        = bool
  default     = true
}

variable "instance_warmup_time" {
  description = "Instance warmup time in seconds"
  type        = number
  default     = 30
}

variable "target_value" {
  description = "Target value for CPU utilization scaling policy"
  type        = number
  default     = 50
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
