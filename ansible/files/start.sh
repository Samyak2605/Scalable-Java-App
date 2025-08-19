#!/bin/bash

# Pet Clinic Application Startup Script
# This script configures the database connection and starts the Java application

set -e  # Exit on any error

# Configuration
JAR_FILE="/home/ubuntu/spring-petclinic-3.5.0-SNAPSHOT.jar"
APP_PROPERTIES="/opt/application.properties"
PROPERTIES_SCRIPT="/home/ubuntu/properties.py"
LOG_FILE="/var/log/petclinic.log"

# Create log file if it doesn't exist
sudo touch $LOG_FILE
sudo chown ubuntu:ubuntu $LOG_FILE

echo "$(date): Starting Pet Clinic application..." | tee -a $LOG_FILE

# Update database configuration
echo "$(date): Updating database configuration..." | tee -a $LOG_FILE
if sudo python3 "$PROPERTIES_SCRIPT"; then
    echo "$(date): Database configuration updated successfully" | tee -a $LOG_FILE
else
    echo "$(date): Failed to update database configuration" | tee -a $LOG_FILE
    exit 1
fi

# Start the Java application
echo "$(date): Starting Java application..." | tee -a $LOG_FILE
sudo java -jar "$JAR_FILE" \
    --spring.config.location="$APP_PROPERTIES" \
    --spring.profiles.active=mysql \
    --server.port=8080 \
    --logging.level.org.springframework.samples.petclinic=INFO \
    >> $LOG_FILE 2>&1 &

# Get the PID of the Java process
JAVA_PID=$!
echo "$(date): Pet Clinic application started with PID: $JAVA_PID" | tee -a $LOG_FILE

# Save PID to file for potential future use
echo $JAVA_PID | sudo tee /var/run/petclinic.pid > /dev/null

echo "$(date): Pet Clinic application startup completed" | tee -a $LOG_FILE
