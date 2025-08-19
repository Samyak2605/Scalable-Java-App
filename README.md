# Scalable Java Application on AWS with Terraform

This project demonstrates how to deploy a scalable Java application (Spring Pet Clinic) on AWS using Infrastructure as Code (IaC) principles with Terraform, Packer, and Ansible.

## 🏗️ Architecture Overview

![Architecture Diagram](architecture.png)

The deployment creates a highly available and scalable architecture including:

- **Application Load Balancer (ALB)** - Distributes traffic across multiple instances
- **Auto Scaling Group (ASG)** - Automatically scales instances based on demand
- **RDS MySQL Database** - Managed database service for persistent data
- **AWS Secrets Manager** - Secure storage for database credentials
- **AWS Parameter Store** - Configuration management for application settings
- **CloudWatch** - Monitoring and logging for the infrastructure and application

## 🛠️ Tools & Services Used

### DevOps Tools
- **Packer** - Build custom AMIs with pre-installed application
- **Ansible** - Configure and provision application during AMI creation
- **Terraform** - Infrastructure as Code for AWS resource provisioning
- **Maven** - Build the Java application
- **Git** - Version control

### AWS Services
- **EC2** - Virtual machines for running the application
- **RDS** - Managed MySQL database
- **ALB** - Application Load Balancer for traffic distribution
- **ASG** - Auto Scaling Group for automatic scaling
- **VPC** - Virtual Private Cloud for network isolation
- **IAM** - Identity and Access Management for permissions
- **Secrets Manager** - Secure credential storage
- **Parameter Store** - Configuration parameter storage
- **CloudWatch** - Monitoring and logging

## 📋 Prerequisites

Before starting the deployment, ensure you have:

### Required Tools
1. **AWS CLI** configured with appropriate credentials
2. **Terraform** (>= 1.0)
3. **Packer** (>= 1.8)
4. **Ansible** (>= 2.9)
5. **Java 17** (OpenJDK)
6. **Maven** (>= 3.6)

### AWS Prerequisites
1. **AWS Account** with administrative access
2. **EC2 Key Pair** in us-west-2 region
3. **Default VPC** with public subnets in us-west-2
4. **IAM permissions** for creating EC2, RDS, ALB, IAM roles, etc.

### Installation Commands
```bash
# Install AWS CLI (macOS)
brew install awscli

# Install Terraform
brew install terraform

# Install Packer
brew install packer

# Install Ansible
brew install ansible

# Install Java 17
brew install openjdk@17

# Install Maven
brew install maven
```

## 🚀 Quick Start

### Step 1: Clone and Prepare the Project

```bash
git clone <your-repository-url>
cd "Scalable Java App"
```

### Step 2: Build the Java Application

The Pet Clinic application is already built and included in the project:

```bash
cd pet-clinic-app
mvn clean install -DskipTests
cd ..
```

### Step 3: Update Configuration Files

#### Update VPC and Subnet Information

You need to update the following files with your actual AWS VPC and subnet IDs:

1. **terraform/vars/rds.tfvars**
2. **terraform/vars/alb-asg.tfvars**

```bash
# Get your default VPC ID
aws ec2 describe-vpcs --filters "Name=is-default,Values=true" --region us-west-2

# Get your subnet IDs
aws ec2 describe-subnets --filters "Name=vpc-id,Values=<your-vpc-id>" --region us-west-2
```

Update the files with your actual values:
```hcl
# Example values to replace in both tfvars files
vpc_id  = "vpc-0a5ca4a92c2e10163"  # Your actual VPC ID
subnets = [
  "subnet-058a7514ba8adbb07",      # Your actual subnet IDs
  "subnet-032f5077729435858",
  "subnet-0dbcd1ac168414927"
]
```

### Step 4: Build the Application AMI

```bash
cd ansible

# Validate the Packer template
packer validate java-app.pkr.hcl

# Build the AMI (this takes 5-10 minutes)
packer build java-app.pkr.hcl
```

**Note the AMI ID** from the output - you'll need it for the next step.

### Step 5: Deploy RDS Database

```bash
cd ../terraform/rds

# Initialize Terraform
terraform init

# Plan the deployment
terraform plan -var-file=../vars/rds.tfvars

# Apply the configuration
terraform apply -var-file=../vars/rds.tfvars
```

### Step 6: Deploy ALB and ASG

Update the AMI ID in `terraform/vars/alb-asg.tfvars`:
```hcl
ami_id = "ami-xxxxxxxxxxxxx"  # Your Packer-built AMI ID
key_name = "your-key-pair-name"  # Your EC2 key pair name
```

```bash
cd ../alb-asg

# Initialize Terraform
terraform init

# Plan the deployment
terraform plan -var-file=../vars/alb-asg.tfvars

# Apply the configuration
terraform apply -var-file=../vars/alb-asg.tfvars
```

### Step 7: Access Your Application

After deployment completes:

1. Get the ALB DNS name from Terraform output
2. Wait 5-10 minutes for instances to fully initialize
3. Access your application at: `http://<alb-dns-name>`

## 📁 Project Structure

```
Scalable Java App/
├── README.md                          # This documentation
├── pet-clinic-app/                    # Spring Pet Clinic source code
│   ├── src/                          # Application source code
│   ├── target/                       # Compiled JAR file
│   └── pom.xml                       # Maven configuration
├── ansible/                          # Ansible configuration for AMI
│   ├── files/                        # Application files
│   │   ├── spring-petclinic-*.jar   # Application JAR file
│   │   ├── properties.py             # AWS configuration script
│   │   └── start.sh                  # Application startup script
│   ├── roles/java/tasks/             # Ansible tasks
│   │   ├── main.yml                  # Main task orchestration
│   │   ├── java.yml                  # Java installation
│   │   ├── python.yml                # Python/Boto3 setup
│   │   ├── app.yml                   # Application deployment
│   │   ├── cloudwatch.yml            # CloudWatch agent setup
│   │   └── backends.yml              # System dependencies
│   ├── templates/                    # Configuration templates
│   │   ├── config.json.j2            # CloudWatch config
│   │   └── application.properties.j2  # App configuration
│   ├── java-app.pkr.hcl              # Packer template
│   └── java-app.yml                  # Ansible playbook
└── terraform/                        # Terraform infrastructure code
    ├── modules/                      # Reusable Terraform modules
    │   ├── rds/                      # RDS module
    │   │   ├── main.tf               # RDS resources
    │   │   ├── variables.tf          # RDS variables
    │   │   └── outputs.tf            # RDS outputs
    │   └── alb-asg/                  # ALB/ASG module
    │       ├── alb.tf                # Load balancer resources
    │       ├── asg.tf                # Auto scaling resources
    │       ├── iam-policy.tf         # IAM roles and policies
    │       └── variable.tf           # ALB/ASG variables
    ├── rds/                          # RDS deployment
    │   ├── main.tf                   # RDS main configuration
    │   └── variables.tf              # RDS variables
    ├── alb-asg/                      # ALB/ASG deployment
    │   ├── main.tf                   # ALB/ASG main configuration
    │   └── variable.tf               # ALB/ASG variables
    └── vars/                         # Variable files
        ├── rds.tfvars                # RDS configuration values
        └── alb-asg.tfvars            # ALB/ASG configuration values
```

## 🔧 Configuration Details

### Database Configuration

The application automatically configures its database connection using:

1. **RDS Endpoint** - Retrieved from AWS Parameter Store
2. **Database Credentials** - Retrieved from AWS Secrets Manager
3. **Connection Properties** - Configured via `properties.py` script

### Security Configuration

- **RDS Security Group** - Allows MySQL access (port 3306)
- **ALB Security Group** - Allows HTTP/HTTPS access (ports 80/443)
- **Instance Security Group** - Allows SSH (port 22) and application access (port 8080)
- **IAM Roles** - Minimal required permissions for accessing AWS services

### Auto Scaling Configuration

- **Target CPU Utilization** - 50% (configurable)
- **Scale Up Policy** - Add 1 instance when CPU > 50% for 2 evaluation periods
- **Scale Down Policy** - Remove 1 instance when CPU < 10% for 2 evaluation periods
- **Health Checks** - ELB health checks with 30-second interval

## 📊 Monitoring and Logging

### CloudWatch Monitoring

The deployment includes comprehensive monitoring:

- **Application Logs** - `/var/log/petclinic.log`
- **System Logs** - `/var/log/syslog`
- **Metrics** - CPU, Memory, Disk, Network utilization
- **Alarms** - Auto scaling triggers based on CPU utilization

### Health Checks

- **ALB Health Checks** - HTTP GET requests to `/` every 30 seconds
- **Auto Scaling Health Checks** - ELB health check integration
- **Instance Health** - CloudWatch agent monitoring

## 🛡️ Security Best Practices

### Implemented Security Measures

1. **Encrypted Storage** - EBS volumes and RDS storage encrypted
2. **Secrets Management** - Database credentials in AWS Secrets Manager
3. **IAM Principle of Least Privilege** - Minimal required permissions
4. **Security Groups** - Restrictive network access rules
5. **Parameter Store** - Secure configuration management

### Additional Security Recommendations

1. **Enable VPC Flow Logs** - For network traffic monitoring
2. **Use AWS WAF** - For web application firewall protection
3. **Implement SSL/TLS** - Add SSL certificate for HTTPS
4. **Enable CloudTrail** - For API call auditing
5. **Use Private Subnets** - Move instances to private subnets with NAT Gateway

## 🚨 Troubleshooting

### Common Issues

#### Packer Build Fails
```bash
# Check Packer logs
packer build -debug java-app.pkr.hcl

# Common solutions:
# - Verify AWS credentials
# - Check VPC and subnet accessibility
# - Ensure security groups allow SSH
```

#### Terraform Apply Fails
```bash
# Check Terraform state
terraform show

# Common solutions:
# - Verify resource limits (VPC, subnet capacity)
# - Check IAM permissions
# - Ensure resource naming conflicts don't exist
```

#### Application Not Accessible
```bash
# Check ALB target health
aws elbv2 describe-target-health --target-group-arn <target-group-arn>

# Check instance logs
aws ssm start-session --target <instance-id>
sudo tail -f /var/log/petclinic.log

# Common solutions:
# - Wait for application startup (2-3 minutes)
# - Check security group rules
# - Verify RDS connectivity
```

#### Database Connection Issues
```bash
# Check RDS status
aws rds describe-db-instances --region us-west-2

# Check secrets manager
aws secretsmanager list-secrets --region us-west-2

# Check parameter store
aws ssm get-parameter --name "/dev/petclinic/rds_endpoint" --region us-west-2
```

### Health Check Commands

```bash
# Check application health
curl http://<alb-dns-name>/actuator/health

# Check database connectivity
curl http://<alb-dns-name>/actuator/health/db

# View application metrics
curl http://<alb-dns-name>/actuator/metrics
```

## 💰 Cost Optimization

### Current Configuration Costs (Estimated)

- **RDS db.t3.micro** - ~$13/month
- **EC2 t2.medium (2 instances)** - ~$67/month
- **ALB** - ~$20/month
- **Data Transfer** - Variable
- **Total Estimated** - ~$100/month

### Cost Optimization Strategies

1. **Use Spot Instances** - Reduce EC2 costs by 50-90%
2. **Implement Reserved Instances** - Save 30-75% on predictable workloads
3. **Auto Scaling** - Scale down during low traffic periods
4. **RDS Optimization** - Use smaller instance types or Aurora Serverless
5. **Monitoring** - Set up billing alerts and cost monitoring

## 🧹 Cleanup

To avoid ongoing charges, clean up resources in reverse order:

```bash
# Destroy ALB and ASG
cd terraform/alb-asg
terraform destroy -var-file=../vars/alb-asg.tfvars

# Destroy RDS
cd ../rds
terraform destroy -var-file=../vars/rds.tfvars

# Delete AMI (optional)
aws ec2 deregister-image --image-id <ami-id> --region us-west-2
aws ec2 describe-snapshots --owner-ids self --region us-west-2
aws ec2 delete-snapshot --snapshot-id <snapshot-id> --region us-west-2
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙋‍♂️ Support

For questions and support:

1. Check the troubleshooting section above
2. Review AWS CloudWatch logs
3. Open an issue in the repository
4. Consult AWS documentation for service-specific issues

## 🔗 Useful Links

- [Spring Pet Clinic Documentation](https://spring-petclinic.github.io/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Packer Documentation](https://www.packer.io/docs)
- [Ansible Documentation](https://docs.ansible.com/)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)

---

**Note**: This project is for educational and demonstration purposes. For production use, implement additional security measures, monitoring, and compliance requirements as needed for your organization.
