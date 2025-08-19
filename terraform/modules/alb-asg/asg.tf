# Auto Scaling Group Configuration

# Security Group for EC2 instances
resource "aws_security_group" "instance_sg" {
  name_prefix = "${var.application}-instance-sg"
  vpc_id      = var.vpc_id
  description = "Security group for EC2 instances in ASG"

  # SSH access
  ingress {
    from_port   = var.ingress_asg_cidr_from_port
    to_port     = var.ingress_asg_cidr_to_port
    protocol    = var.ingress_asg_cidr_protocol
    cidr_blocks = var.ingress_asg_cidr_blocks
    description = "SSH access"
  }

  # Application port access from ALB
  ingress {
    from_port       = var.ingress_asg_sg_from_port
    to_port         = var.ingress_asg_sg_to_port
    protocol        = var.ingress_asg_sg_protocol
    security_groups = [aws_security_group.alb_sg.id]
    description     = "Application access from ALB"
  }

  # Health check port access from ALB
  ingress {
    from_port       = var.health_check_port
    to_port         = var.health_check_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
    description     = "Health check access from ALB"
  }

  egress {
    from_port   = var.egress_asg_from_port
    to_port     = var.egress_asg_to_port
    protocol    = var.egress_asg_protocol
    cidr_blocks = var.egress_asg_cidr_blocks
    description = "All outbound traffic"
  }

  tags = {
    Name        = "${var.application}-instance-sg"
    Owner       = var.owner
    Environment = var.environment
    CostCenter  = var.cost_center
    Application = var.application
  }
}

# Launch Template for ASG
resource "aws_launch_template" "app_lt" {
  name_prefix   = "${var.application}-lt"
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name

  # IAM instance profile
  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  # VPC security groups
  vpc_security_group_ids = [aws_security_group.instance_sg.id]

  # Network interface configuration
  network_interfaces {
    associate_public_ip_address = var.public_access
    security_groups            = [aws_security_group.instance_sg.id]
    delete_on_termination      = true
  }

  # Block device mapping
  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_size           = 20
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  }

  # User data script
  user_data = base64encode(var.user_data)

  # Instance metadata options
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
    instance_metadata_tags      = "enabled"
  }

  # Monitoring
  monitoring {
    enabled = true
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "${var.application}-instance"
      Owner       = var.owner
      Environment = var.environment
      CostCenter  = var.cost_center
      Application = var.application
    }
  }

  tag_specifications {
    resource_type = "volume"
    tags = {
      Name        = "${var.application}-volume"
      Owner       = var.owner
      Environment = var.environment
      CostCenter  = var.cost_center
      Application = var.application
    }
  }

  tags = {
    Name        = "${var.application}-launch-template"
    Owner       = var.owner
    Environment = var.environment
    CostCenter  = var.cost_center
    Application = var.application
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "app_asg" {
  name                = "${var.application}-asg"
  vpc_zone_identifier = var.subnets
  target_group_arns   = [aws_lb_target_group.app_tg.arn]
  health_check_type   = "ELB"
  health_check_grace_period = 300

  # Capacity configuration
  min_size         = var.min_size
  max_size         = var.max_size
  desired_capacity = var.desired_capacity

  # Launch template configuration
  launch_template {
    id      = aws_launch_template.app_lt.id
    version = "$Latest"
  }

  # Instance refresh configuration
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
      instance_warmup        = var.instance_warmup_time
    }
  }

  # Termination policies
  termination_policies = ["OldestInstance"]

  # Availability zone distribution
  availability_zones = data.aws_availability_zones.available.names

  # Tags
  tag {
    key                 = "Name"
    value               = "${var.application}-asg-instance"
    propagate_at_launch = true
  }

  tag {
    key                 = "Owner"
    value               = var.owner
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }

  tag {
    key                 = "CostCenter"
    value               = var.cost_center
    propagate_at_launch = true
  }

  tag {
    key                 = "Application"
    value               = var.application
    propagate_at_launch = true
  }

  depends_on = [
    aws_lb_target_group.app_tg,
    aws_launch_template.app_lt
  ]
}

# Auto Scaling Policy - Scale Up
resource "aws_autoscaling_policy" "scale_up" {
  name                   = "${var.application}-scale-up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.app_asg.name
  policy_type            = "SimpleScaling"
}

# Auto Scaling Policy - Scale Down
resource "aws_autoscaling_policy" "scale_down" {
  name                   = "${var.application}-scale-down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.app_asg.name
  policy_type            = "SimpleScaling"
}

# CloudWatch Alarm - High CPU Utilization
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${var.application}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = var.target_value
  alarm_description   = "This metric monitors ec2 cpu utilization"
  alarm_actions       = [aws_autoscaling_policy.scale_up.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app_asg.name
  }

  tags = {
    Name        = "${var.application}-high-cpu-alarm"
    Owner       = var.owner
    Environment = var.environment
    CostCenter  = var.cost_center
    Application = var.application
  }
}

# CloudWatch Alarm - Low CPU Utilization
resource "aws_cloudwatch_metric_alarm" "low_cpu" {
  alarm_name          = "${var.application}-low-cpu"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = 10
  alarm_description   = "This metric monitors ec2 cpu utilization"
  alarm_actions       = [aws_autoscaling_policy.scale_down.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app_asg.name
  }

  tags = {
    Name        = "${var.application}-low-cpu-alarm"
    Owner       = var.owner
    Environment = var.environment
    CostCenter  = var.cost_center
    Application = var.application
  }
}

# Data source for availability zones
data "aws_availability_zones" "available" {
  state = "available"
}
