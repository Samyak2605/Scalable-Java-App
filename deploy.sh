#!/bin/bash

# Scalable Java Application Deployment Script
# This script automates the deployment of the Pet Clinic application on AWS

set -e  # Exit on any error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if a command exists
check_command() {
    if ! command -v $1 &> /dev/null; then
        print_error "$1 is not installed. Please install it before continuing."
        exit 1
    fi
}

# Function to validate AWS credentials
check_aws_credentials() {
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials not configured. Please run 'aws configure' first."
        exit 1
    fi
}

# Function to get user confirmation
confirm() {
    read -p "$1 (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        return 1
    fi
}

# Check prerequisites
print_status "Checking prerequisites..."
check_command "aws"
check_command "terraform"
check_command "packer"
check_command "ansible"
check_command "mvn"
check_command "java"

check_aws_credentials

print_status "All prerequisites met!"

# Get AWS account info
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION="us-west-2"
print_status "Deploying to AWS Account: $AWS_ACCOUNT_ID in region: $AWS_REGION"

# Step 1: Build Java Application
print_status "Step 1: Building Java application..."
if [ -f "pet-clinic-app/target/spring-petclinic-3.5.0-SNAPSHOT.jar" ]; then
    print_status "JAR file already exists. Skipping build."
else
    cd pet-clinic-app
    mvn clean install -DskipTests
    cd ..
    
    # Copy JAR to ansible files
    cp pet-clinic-app/target/spring-petclinic-3.5.0-SNAPSHOT.jar ansible/files/
fi

# Step 2: Check and update configuration
print_status "Step 2: Checking configuration files..."

# Check if VPC configuration is updated
if grep -q "vpc-12345678" terraform/vars/rds.tfvars; then
    print_warning "VPC and subnet IDs need to be updated in terraform/vars/rds.tfvars"
    print_warning "Please update the following files with your actual AWS VPC and subnet IDs:"
    print_warning "- terraform/vars/rds.tfvars"
    print_warning "- terraform/vars/alb-asg.tfvars"
    
    # Get VPC info
    DEFAULT_VPC=$(aws ec2 describe-vpcs --filters "Name=is-default,Values=true" --query 'Vpcs[0].VpcId' --output text --region $AWS_REGION)
    if [ "$DEFAULT_VPC" != "None" ] && [ "$DEFAULT_VPC" != "" ]; then
        print_status "Found default VPC: $DEFAULT_VPC"
        
        # Get subnet IDs
        SUBNETS=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$DEFAULT_VPC" --query 'Subnets[0:3].SubnetId' --output text --region $AWS_REGION)
        print_status "Found subnets: $SUBNETS"
        
        if confirm "Would you like to automatically update the configuration files with these values?"; then
            # Update RDS tfvars
            sed -i '' "s/vpc_id.*=.*/vpc_id = \"$DEFAULT_VPC\"/" terraform/vars/rds.tfvars
            
            # Convert space-separated subnets to array format
            SUBNET_ARRAY=$(echo $SUBNETS | awk '{print "[\""$1"\", \""$2"\", \""$3"\"]"}')
            sed -i '' "s/subnet_ids.*=.*/subnet_ids = $SUBNET_ARRAY/" terraform/vars/rds.tfvars
            
            # Update ALB-ASG tfvars
            sed -i '' "s/vpc_id.*=.*/vpc_id = \"$DEFAULT_VPC\"/" terraform/vars/alb-asg.tfvars
            sed -i '' "s/subnets.*=.*/subnets = $SUBNET_ARRAY/" terraform/vars/alb-asg.tfvars
            
            print_status "Configuration files updated!"
        else
            print_error "Please update the configuration files manually and run the script again."
            exit 1
        fi
    else
        print_error "No default VPC found. Please update configuration files manually."
        exit 1
    fi
fi

# Step 3: Build AMI with Packer
print_status "Step 3: Building AMI with Packer..."
cd ansible

if confirm "Do you want to build a new AMI? (This takes 5-10 minutes)"; then
    print_status "Validating Packer template..."
    packer validate java-app.pkr.hcl
    
    print_status "Building AMI... This may take several minutes."
    packer build java-app.pkr.hcl
    
    # Extract AMI ID from Packer output
    AMI_ID=$(jq -r '.builds[0].artifact_id' packer-manifest.json | cut -d: -f2)
    print_status "AMI built successfully: $AMI_ID"
    
    # Update alb-asg.tfvars with new AMI ID
    cd ..
    sed -i '' "s/ami_id.*=.*/ami_id = \"$AMI_ID\"/" terraform/vars/alb-asg.tfvars
    print_status "Updated alb-asg.tfvars with new AMI ID"
else
    cd ..
    # Check if AMI ID is set
    CURRENT_AMI=$(grep ami_id terraform/vars/alb-asg.tfvars | cut -d'"' -f2)
    if [ "$CURRENT_AMI" = "ami-0123456789abcdef0" ]; then
        print_error "AMI ID not set in terraform/vars/alb-asg.tfvars. Please build an AMI first."
        exit 1
    fi
    print_status "Using existing AMI: $CURRENT_AMI"
fi

# Check EC2 key pair
CURRENT_KEY=$(grep key_name terraform/vars/alb-asg.tfvars | cut -d'"' -f2)
if [ "$CURRENT_KEY" = "your-key-pair" ]; then
    print_warning "EC2 key pair not set in terraform/vars/alb-asg.tfvars"
    
    # List available key pairs
    KEY_PAIRS=$(aws ec2 describe-key-pairs --query 'KeyPairs[].KeyName' --output text --region $AWS_REGION)
    if [ -n "$KEY_PAIRS" ]; then
        print_status "Available key pairs: $KEY_PAIRS"
        read -p "Enter the key pair name to use: " KEY_NAME
        sed -i '' "s/key_name.*=.*/key_name = \"$KEY_NAME\"/" terraform/vars/alb-asg.tfvars
        print_status "Updated key pair name"
    else
        print_error "No EC2 key pairs found. Please create one first."
        exit 1
    fi
fi

# Step 4: Deploy RDS
print_status "Step 4: Deploying RDS database..."
cd terraform/rds

if confirm "Do you want to deploy the RDS database?"; then
    terraform init
    terraform plan -var-file=../vars/rds.tfvars
    
    if confirm "Do you want to apply the RDS configuration?"; then
        terraform apply -var-file=../vars/rds.tfvars -auto-approve
        print_status "RDS deployment completed!"
    else
        print_warning "RDS deployment skipped"
    fi
else
    print_warning "RDS deployment skipped"
fi

# Step 5: Deploy ALB and ASG
print_status "Step 5: Deploying ALB and Auto Scaling Group..."
cd ../alb-asg

if confirm "Do you want to deploy the ALB and ASG?"; then
    terraform init
    terraform plan -var-file=../vars/alb-asg.tfvars
    
    if confirm "Do you want to apply the ALB/ASG configuration?"; then
        terraform apply -var-file=../vars/alb-asg.tfvars -auto-approve
        
        # Get ALB DNS name
        ALB_DNS=$(terraform output -raw alb_dns_name 2>/dev/null || echo "Check Terraform outputs for ALB DNS name")
        
        print_status "Deployment completed successfully!"
        print_status "ALB DNS Name: $ALB_DNS"
        print_status "Application URL: http://$ALB_DNS"
        print_warning "Note: It may take 5-10 minutes for the application to be fully available."
    else
        print_warning "ALB/ASG deployment skipped"
    fi
else
    print_warning "ALB/ASG deployment skipped"
fi

cd ../..

print_status "Deployment script completed!"
print_status "Next steps:"
print_status "1. Wait 5-10 minutes for instances to initialize"
print_status "2. Check target group health in AWS Console"
print_status "3. Access your application at the ALB DNS name"
print_status "4. Monitor logs and metrics in CloudWatch"
