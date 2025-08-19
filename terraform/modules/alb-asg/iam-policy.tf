# IAM Role and Policy for EC2 instances in ASG

# IAM Role for EC2 instances
resource "aws_iam_role" "ec2_role" {
  name = "${var.application}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.application}-ec2-role"
    Owner       = var.owner
    Environment = var.environment
    CostCenter  = var.cost_center
    Application = var.application
  }
}

# IAM Policy for accessing AWS services
resource "aws_iam_policy" "ec2_policy" {
  name        = "${var.application}-ec2-policy"
  description = "Policy for EC2 instances to access required AWS services"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # CloudWatch Logs permissions
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "*"
      },
      # CloudWatch Metrics permissions
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics"
        ]
        Resource = "*"
      },
      # EC2 permissions for CloudWatch agent
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeVolumes",
          "ec2:DescribeTags",
          "ec2:DescribeInstances"
        ]
        Resource = "*"
      },
      # SSM permissions for Parameter Store
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath",
          "ssm:DescribeParameters"
        ]
        Resource = [
          "arn:aws:ssm:${var.region}:*:parameter/dev/petclinic/*",
          "arn:aws:ssm:${var.region}:*:parameter/${var.application}/*"
        ]
      },
      # Secrets Manager permissions
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecrets"
        ]
        Resource = "*"
      },
      # S3 permissions for potential future use
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = [
          "arn:aws:s3:::${var.application}-*/*"
        ]
      },
      # Auto Scaling permissions
      {
        Effect = "Allow"
        Action = [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name        = "${var.application}-ec2-policy"
    Owner       = var.owner
    Environment = var.environment
    CostCenter  = var.cost_center
    Application = var.application
  }
}

# Attach CloudWatch Agent Server policy
resource "aws_iam_role_policy_attachment" "cloudwatch_agent_server_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Attach SSM Managed Instance Core policy
resource "aws_iam_role_policy_attachment" "ssm_managed_instance_core" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Attach custom policy to role
resource "aws_iam_role_policy_attachment" "ec2_policy_attachment" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.ec2_policy.arn
}

# Create instance profile
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.application}-ec2-profile"
  role = aws_iam_role.ec2_role.name

  tags = {
    Name        = "${var.application}-ec2-profile"
    Owner       = var.owner
    Environment = var.environment
    CostCenter  = var.cost_center
    Application = var.application
  }
}
