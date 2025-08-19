# Architecture Documentation

## System Architecture

```
                                    ┌─────────────┐
                                    │   Internet  │
                                    └──────┬──────┘
                                           │
                                           ▼
                                  ┌────────────────┐
                                  │ Application    │
                                  │ Load Balancer  │
                                  │ (ALB)          │
                                  └───┬────────┬───┘
                                      │        │
                          ┌───────────▼─┐    ┌─▼───────────┐
                          │   Subnet A   │    │   Subnet B   │
                          │   (AZ-1)     │    │   (AZ-2)     │
                          └───┬─────────┬┘    └┬─────────┬───┘
                              │         │      │         │
                        ┌─────▼───┐ ┌───▼─┐  ┌─▼───┐ ┌───▼─────┐
                        │EC2      │ │EC2  │  │EC2  │ │EC2      │
                        │Instance │ │Inst │  │Inst │ │Instance │
                        │1        │ │2    │  │3    │ │N        │
                        └─────────┘ └─────┘  └─────┘ └─────────┘
                              │         │      │         │
                              └─────────┼──────┼─────────┘
                                        │      │
                                        ▼      ▼
                                    ┌────────────────┐
                                    │ AWS Secrets    │
                                    │ Manager        │
                                    └────────────────┘
                                    ┌────────────────┐
                                    │ AWS Parameter  │
                                    │ Store          │
                                    └────────────────┘
                                           │
                                           ▼
                                  ┌────────────────┐
                                  │ RDS MySQL      │
                                  │ Database       │
                                  │ (Multi-AZ)     │
                                  └────────────────┘
```

## Component Details

### 1. Application Load Balancer (ALB)
- **Purpose**: Distributes incoming traffic across multiple EC2 instances
- **Features**: 
  - Layer 7 load balancing
  - Health checks
  - SSL termination (configurable)
  - Path-based routing
- **Security**: Public-facing with security group allowing HTTP/HTTPS

### 2. Auto Scaling Group (ASG)
- **Purpose**: Automatically manages EC2 instance capacity
- **Features**:
  - Horizontal scaling based on CPU utilization
  - Multi-AZ deployment for high availability
  - Rolling updates and instance refresh
- **Scaling Policies**:
  - Scale up: CPU > 50% for 2 evaluation periods
  - Scale down: CPU < 10% for 2 evaluation periods

### 3. EC2 Instances
- **AMI**: Custom-built with Packer containing:
  - Ubuntu 20.04 LTS
  - OpenJDK 17
  - Python 3 with boto3
  - CloudWatch Agent
  - Spring Pet Clinic application
- **Instance Type**: t2.medium (configurable)
- **Security**: Instance security group allowing ALB traffic and SSH

### 4. RDS MySQL Database
- **Purpose**: Persistent data storage for the application
- **Features**:
  - Managed MySQL 8.0
  - Automated backups
  - Security group protection
  - Multi-AZ option for high availability
- **Security**: Database credentials stored in AWS Secrets Manager

### 5. AWS Secrets Manager
- **Purpose**: Secure storage of database credentials
- **Features**:
  - Automatic password generation
  - Encryption at rest and in transit
  - Fine-grained access control via IAM

### 6. AWS Parameter Store
- **Purpose**: Store application configuration parameters
- **Usage**: Stores RDS endpoint for dynamic application configuration

### 7. CloudWatch
- **Purpose**: Monitoring and logging
- **Features**:
  - Application logs from `/var/log/petclinic.log`
  - System metrics (CPU, memory, disk, network)
  - Auto scaling alarms
  - Custom application metrics

## Network Architecture

### VPC Configuration
- **VPC**: Default VPC in us-west-2 region
- **Subnets**: Public subnets across multiple Availability Zones
- **Internet Gateway**: Provides internet access
- **Route Tables**: Default routing configuration

### Security Groups

#### ALB Security Group
```
Inbound Rules:
- HTTP (80) from 0.0.0.0/0
- HTTPS (443) from 0.0.0.0/0

Outbound Rules:
- All traffic to 0.0.0.0/0
```

#### Instance Security Group
```
Inbound Rules:
- SSH (22) from 0.0.0.0/0
- HTTP (8080) from ALB Security Group

Outbound Rules:
- All traffic to 0.0.0.0/0
```

#### RDS Security Group
```
Inbound Rules:
- MySQL (3306) from Instance Security Group

Outbound Rules:
- All traffic to 0.0.0.0/0
```

## Data Flow

### Request Flow
1. **Client Request** → ALB receives HTTP request from internet
2. **Load Balancing** → ALB forwards request to healthy EC2 instance
3. **Application Processing** → Spring Boot app processes the request
4. **Database Query** → Application queries RDS MySQL if needed
5. **Response** → Response flows back through ALB to client

### Configuration Flow
1. **Instance Startup** → EC2 instance boots with custom AMI
2. **Credential Retrieval** → Instance retrieves DB credentials from Secrets Manager
3. **Configuration Update** → Instance gets RDS endpoint from Parameter Store
4. **Application Start** → Spring Boot application starts with updated configuration

### Monitoring Flow
1. **Metrics Collection** → CloudWatch agent collects system and application metrics
2. **Log Aggregation** → Application logs sent to CloudWatch Logs
3. **Alarm Evaluation** → CloudWatch evaluates scaling alarms
4. **Auto Scaling** → ASG responds to scaling events

## High Availability Features

### Multi-AZ Deployment
- EC2 instances distributed across multiple Availability Zones
- ALB health checks ensure traffic only goes to healthy instances
- RDS can be configured for Multi-AZ deployment

### Fault Tolerance
- If an instance fails, ASG automatically replaces it
- ALB removes unhealthy instances from rotation
- Database backups provide data recovery capability

### Scalability
- Auto Scaling Group handles traffic spikes automatically
- Load balancer distributes traffic evenly
- RDS can be scaled vertically or horizontally (read replicas)

## Security Features

### Network Security
- Security groups act as virtual firewalls
- Principle of least privilege access
- VPC provides network isolation

### Data Security
- Database credentials encrypted in Secrets Manager
- EBS volumes encrypted at rest
- RDS storage encrypted
- SSL/TLS encryption in transit (configurable)

### Access Control
- IAM roles for EC2 instances with minimal required permissions
- Instance profile attached to EC2 instances
- No hardcoded credentials in application

## Operational Considerations

### Monitoring
- CloudWatch dashboards for system overview
- Alarms for critical metrics
- Log aggregation for troubleshooting

### Backup and Recovery
- RDS automated backups (7 days retention)
- AMI snapshots for disaster recovery
- Terraform state for infrastructure recovery

### Cost Optimization
- Auto Scaling reduces costs during low traffic
- Spot instances can be used for development
- Reserved instances for predictable workloads

### Maintenance
- Rolling updates through ASG instance refresh
- Blue-green deployments possible with additional ALB configuration
- Database maintenance windows during low traffic periods
