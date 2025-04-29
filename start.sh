#!/bin/bash

# Script to create an S3 bucket
# Usage: ./start.sh [bucket-name] [region]
# Or set S3_BUCKET_NAME environment variable

# Check if bucket name is provided as argument or environment variable
if [ -z "$1" ] && [ -z "$S3_BUCKET_NAME" ]; then
    echo "Error: Bucket name is required"
    echo "Usage: ./start.sh [bucket-name] [region]"
    echo "Or set S3_BUCKET_NAME environment variable"
    exit 1
fi

# Set the bucket name from argument or environment variable
BUCKET_NAME=${1:-$AWS_REGION}

# Set the region (default to us-east-1 if not provided)
REGION=${2:-us-east-1}

echo "Creating S3 bucket: $BUCKET_NAME in region: $REGION"

# Create the bucket
aws s3api create-bucket \
    --bucket $BUCKET_NAME \
    --region $REGION \
    $(if [ "$REGION" != "us-east-1" ]; then echo "--create-bucket-configuration LocationConstraint=$REGION"; fi)

# Check if the bucket was created successfully
if [ $? -eq 0 ]; then
    echo "Bucket $BUCKET_NAME created successfully!"
    
    # Enable versioning (optional)
    aws s3api put-bucket-versioning \
        --bucket $BUCKET_NAME \
        --versioning-configuration Status=Enabled
    
    echo "Bucket versioning enabled"
    
    # List the buckets to confirm
    echo "Current S3 buckets:"
    aws s3 ls
else
    echo "Failed to create bucket $BUCKET_NAME"
    exit 1
fi