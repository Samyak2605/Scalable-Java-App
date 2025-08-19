#!/usr/bin/env python3
"""
AWS RDS Configuration Script
Retrieves RDS credentials from AWS Secrets Manager and endpoint from Parameter Store
Updates application properties file with database connection details
"""

import boto3
import json
import logging

# Configuration constants
REGION = 'us-west-2'
PARAMETER_STORE_PATH = '/dev/petclinic/rds_endpoint'
SECRET_NAME_TAG = 'dev-rds-db'
APPLICATION_PROPERTIES_PATH = "/opt/application.properties"

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

def get_rds_endpoint():
    """Retrieve RDS endpoint from AWS Parameter Store"""
    try:
        ssm_client = boto3.client('ssm', region_name=REGION)
        response = ssm_client.get_parameter(Name=PARAMETER_STORE_PATH)
        endpoint = response['Parameter']['Value']
        logger.info(f"Retrieved RDS endpoint: {endpoint}")
        return endpoint
    except Exception as e:
        logger.error(f"Failed to retrieve RDS endpoint: {e}")
        raise

def get_rds_credentials():
    """Retrieve RDS credentials from AWS Secrets Manager"""
    try:
        secrets_client = boto3.client('secretsmanager', region_name=REGION)
        
        # List all secrets and find the one with matching tag
        secrets_list = secrets_client.list_secrets()
        secret_arn = None
        
        for secret in secrets_list['SecretList']:
            if 'Tags' in secret:
                for tag in secret['Tags']:
                    if tag['Key'] == 'Name' and tag['Value'] == SECRET_NAME_TAG:
                        secret_arn = secret['ARN']
                        break
        
        if not secret_arn:
            raise ValueError(f"Secret with name tag '{SECRET_NAME_TAG}' not found")
        
        # Retrieve secret value
        response = secrets_client.get_secret_value(SecretId=secret_arn)
        secret_data = json.loads(response['SecretString'])
        
        logger.info("Successfully retrieved RDS credentials")
        return secret_data
    except Exception as e:
        logger.error(f"Failed to retrieve RDS credentials: {e}")
        raise

def update_application_properties(rds_endpoint, credentials):
    """Update application.properties file with RDS connection details"""
    try:
        # Read the current properties file
        with open(APPLICATION_PROPERTIES_PATH, 'r') as file:
            content = file.read()
        
        # Replace database connection properties
        replacements = {
            "spring.datasource.url=jdbc:mysql://localhost:3306/petclinic": 
                f"spring.datasource.url=jdbc:mysql://{rds_endpoint}:3306/petclinic",
            "spring.datasource.username=petclinic": 
                f"spring.datasource.username={credentials['username']}",
            "spring.datasource.password=petclinic": 
                f"spring.datasource.password={credentials['password']}"
        }
        
        for old_value, new_value in replacements.items():
            content = content.replace(old_value, new_value)
        
        # Write updated content back to file
        with open(APPLICATION_PROPERTIES_PATH, 'w') as file:
            file.write(content)
        
        logger.info("Successfully updated application.properties file")
    except Exception as e:
        logger.error(f"Failed to update application properties: {e}")
        raise

def main():
    """Main function to orchestrate the configuration update"""
    try:
        logger.info("Starting RDS configuration update...")
        
        # Get RDS connection details
        rds_endpoint = get_rds_endpoint()
        rds_credentials = get_rds_credentials()
        
        # Update application properties
        update_application_properties(rds_endpoint, rds_credentials)
        
        logger.info("RDS configuration update completed successfully")
    except Exception as e:
        logger.error(f"Configuration update failed: {e}")
        exit(1)

if __name__ == "__main__":
    main()
