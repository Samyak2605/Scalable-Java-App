#!/bin/bash

# Cleanup Script for Scalable Java Application
# This script destroys all AWS resources created by the deployment

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

# Function to get user confirmation
confirm() {
    read -p "$1 (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        return 1
    fi
}

print_warning "This script will destroy ALL AWS resources created by the Pet Clinic deployment."
print_warning "This action cannot be undone!"

if ! confirm "Are you sure you want to proceed with cleanup?"; then
    print_status "Cleanup cancelled."
    exit 0
fi

print_status "Starting cleanup process..."

# Step 1: Destroy ALB and ASG
print_status "Step 1: Destroying ALB and Auto Scaling Group..."
cd terraform/alb-asg

if [ -f "terraform.tfstate" ]; then
    if confirm "Destroy ALB and ASG resources?"; then
        terraform destroy -var-file=../vars/alb-asg.tfvars -auto-approve
        print_status "ALB and ASG destroyed successfully!"
    else
        print_warning "ALB/ASG cleanup skipped"
    fi
else
    print_warning "No ALB/ASG Terraform state found - skipping"
fi

# Step 2: Destroy RDS
print_status "Step 2: Destroying RDS database..."
cd ../rds

if [ -f "terraform.tfstate" ]; then
    if confirm "Destroy RDS database? (This will delete all data permanently)"; then
        terraform destroy -var-file=../vars/rds.tfvars -auto-approve
        print_status "RDS destroyed successfully!"
    else
        print_warning "RDS cleanup skipped"
    fi
else
    print_warning "No RDS Terraform state found - skipping"
fi

cd ../..

# Step 3: Clean up AMIs (optional)
print_status "Step 3: AMI cleanup..."

if [ -f "ansible/packer-manifest.json" ]; then
    AMI_ID=$(jq -r '.builds[0].artifact_id' ansible/packer-manifest.json | cut -d: -f2)
    if [ "$AMI_ID" != "null" ] && [ -n "$AMI_ID" ]; then
        print_status "Found AMI: $AMI_ID"
        if confirm "Do you want to deregister and delete the custom AMI?"; then
            # Get snapshot ID before deregistering AMI
            SNAPSHOT_ID=$(aws ec2 describe-images --image-ids $AMI_ID --query 'Images[0].BlockDeviceMappings[0].Ebs.SnapshotId' --output text --region us-west-2)
            
            # Deregister AMI
            aws ec2 deregister-image --image-id $AMI_ID --region us-west-2
            print_status "AMI $AMI_ID deregistered"
            
            # Delete snapshot if it exists
            if [ "$SNAPSHOT_ID" != "None" ] && [ -n "$SNAPSHOT_ID" ]; then
                aws ec2 delete-snapshot --snapshot-id $SNAPSHOT_ID --region us-west-2
                print_status "Snapshot $SNAPSHOT_ID deleted"
            fi
            
            # Remove manifest file
            rm -f ansible/packer-manifest.json
        else
            print_warning "AMI cleanup skipped"
        fi
    fi
else
    print_warning "No Packer manifest found - skipping AMI cleanup"
fi

# Step 4: Clean up local files (optional)
print_status "Step 4: Local file cleanup..."

if confirm "Do you want to clean up local Terraform state files?"; then
    find terraform -name "terraform.tfstate*" -delete
    find terraform -name ".terraform" -type d -exec rm -rf {} + 2>/dev/null || true
    find terraform -name ".terraform.lock.hcl" -delete 2>/dev/null || true
    print_status "Local Terraform files cleaned up"
else
    print_warning "Local file cleanup skipped"
fi

print_status "Cleanup completed!"
print_status "Summary of actions taken:"
print_status "- ALB and ASG resources destroyed (if confirmed)"
print_status "- RDS database destroyed (if confirmed)"
print_status "- Custom AMI deregistered (if confirmed)"
print_status "- Local state files cleaned up (if confirmed)"

print_warning "Please verify in AWS Console that all resources have been properly cleaned up."
print_status "You can also check for any remaining resources with:"
print_status "aws ec2 describe-instances --region us-west-2"
print_status "aws rds describe-db-instances --region us-west-2"
print_status "aws elbv2 describe-load-balancers --region us-west-2"
