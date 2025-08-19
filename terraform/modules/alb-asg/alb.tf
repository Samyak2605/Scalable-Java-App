# Application Load Balancer Configuration

# Security Group for ALB
resource "aws_security_group" "alb_sg" {
  name_prefix = "${var.application}-alb-sg"
  vpc_id      = var.vpc_id
  description = "Security group for Application Load Balancer"

  ingress {
    from_port   = var.ingress_alb_from_port
    to_port     = var.ingress_alb_to_port
    protocol    = var.ingress_alb_protocol
    cidr_blocks = var.ingress_alb_cidr_blocks
    description = "HTTP access from internet"
  }

  # HTTPS access if needed
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.ingress_alb_cidr_blocks
    description = "HTTPS access from internet"
  }

  egress {
    from_port   = var.egress_alb_from_port
    to_port     = var.egress_alb_to_port
    protocol    = var.egress_alb_protocol
    cidr_blocks = var.egress_alb_cidr_blocks
    description = "All outbound traffic"
  }

  tags = {
    Name        = "${var.application}-alb-sg"
    Owner       = var.owner
    Environment = var.environment
    CostCenter  = var.cost_center
    Application = var.application
  }
}

# Application Load Balancer
resource "aws_lb" "app_lb" {
  name               = "${var.application}-alb"
  internal           = var.internal
  load_balancer_type = var.loadbalancer_type
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = var.subnets

  enable_deletion_protection = false
  
  # Access logs (optional, requires S3 bucket)
  # access_logs {
  #   bucket  = aws_s3_bucket.lb_access_logs.bucket
  #   prefix  = "test-lb"
  #   enabled = true
  # }

  tags = {
    Name        = "${var.application}-alb"
    Owner       = var.owner
    Environment = var.environment
    CostCenter  = var.cost_center
    Application = var.application
  }
}

# Target Group for ALB
resource "aws_lb_target_group" "app_tg" {
  name     = "${var.application}-tg"
  port     = var.target_group_port
  protocol = var.target_group_protocol
  vpc_id   = var.vpc_id

  # Target group configuration
  target_type                       = var.target_type
  load_balancing_algorithm_type     = var.load_balancing_algorithm
  deregistration_delay              = 30
  load_balancing_cross_zone_enabled = true

  # Health check configuration
  health_check {
    enabled             = true
    healthy_threshold   = var.health_check_healthy_threshold
    unhealthy_threshold = var.health_check_unhealthy_threshold
    timeout             = var.health_check_timeout
    interval            = var.health_check_interval
    path                = var.health_check_path
    matcher             = "200"
    port                = var.health_check_port
    protocol            = var.health_check_protocol
  }

  # Stickiness configuration (optional)
  stickiness {
    type            = "lb_cookie"
    cookie_duration = 86400
    enabled         = false
  }

  tags = {
    Name        = "${var.application}-tg"
    Owner       = var.owner
    Environment = var.environment
    CostCenter  = var.cost_center
    Application = var.application
  }
}

# ALB Listener for HTTP
resource "aws_lb_listener" "app_listener" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = var.listener_port
  protocol          = var.listener_protocol

  default_action {
    type             = var.listener_type
    target_group_arn = aws_lb_target_group.app_tg.arn
  }

  tags = {
    Name        = "${var.application}-listener"
    Owner       = var.owner
    Environment = var.environment
    CostCenter  = var.cost_center
    Application = var.application
  }
}

# ALB Listener for HTTPS (optional, requires SSL certificate)
# resource "aws_lb_listener" "app_listener_https" {
#   load_balancer_arn = aws_lb.app_lb.arn
#   port              = "443"
#   protocol          = "HTTPS"
#   ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
#   certificate_arn   = aws_acm_certificate.cert.arn
# 
#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.app_tg.arn
#   }
# }
