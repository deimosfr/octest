#!/bin/bash

# Script to delete an S3 bucket
# Usage: ./stop.sh [bucket-name]

# Check if bucket name is provided
if [ -z "$1" ]; then
    echo "Error: Bucket name is required"
    echo "Usage: ./stop.sh [bucket-name]"
    exit 1
fi

# Set the bucket name
BUCKET_NAME=$1

echo "Preparing to delete S3 bucket: $BUCKET_NAME"

# First, remove all objects from the bucket (including versions)
echo "Removing all objects from the bucket..."
aws s3api list-object-versions --bucket $BUCKET_NAME --output json --query '{Objects: Versions[].{Key:Key,VersionId:VersionId}}' | \
jq -c '.Objects[] | select(.Key != null)' | \
while read -r object; do
    KEY=$(echo $object | jq -r '.Key')
    VERSION_ID=$(echo $object | jq -r '.VersionId')
    echo "Deleting object: $KEY (version $VERSION_ID)"
    aws s3api delete-object --bucket $BUCKET_NAME --key "$KEY" --version-id "$VERSION_ID"
done

# Delete delete markers as well
echo "Removing delete markers..."
aws s3api list-object-versions --bucket $BUCKET_NAME --output json --query '{Objects: DeleteMarkers[].{Key:Key,VersionId:VersionId}}' | \
jq -c '.Objects[] | select(.Key != null)' | \
while read -r object; do
    KEY=$(echo $object | jq -r '.Key')
    VERSION_ID=$(echo $object | jq -r '.VersionId')
    echo "Deleting delete marker: $KEY (version $VERSION_ID)"
    aws s3api delete-object --bucket $BUCKET_NAME --key "$KEY" --version-id "$VERSION_ID"
done

# For simpler buckets, this might be sufficient:
echo "Removing any remaining objects..."
aws s3 rm s3://$BUCKET_NAME --recursive

# Delete the bucket
echo "Deleting bucket: $BUCKET_NAME"
aws s3api delete-bucket --bucket $BUCKET_NAME

# Check if the bucket was deleted successfully
if [ $? -eq 0 ]; then
    echo "Bucket $BUCKET_NAME deleted successfully!"
    
    # List the buckets to confirm
    echo "Current S3 buckets:"
    aws s3 ls
else
    echo "Failed to delete bucket $BUCKET_NAME. Check if it's empty."
    exit 1
fi