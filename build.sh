#!/bin/bash

# Build script for Lambda deployment packages
# This script creates the ZIP files needed for Terraform deployment

echo "Building Lambda deployment packages..."

# Create lambda directory if it doesn't exist
mkdir -p lambda

# Build shorten function
echo "Building shorten.zip..."
cd lambda

# Create temporary directory for dependencies
mkdir -p temp_shorten
cd temp_shorten

# Install dependencies
pip install -r ../requirements.txt -t .

# Copy the function code
cp ../shorten.py .

# Create zip file
zip -r ../shorten.zip .

# Clean up
cd ..
rm -rf temp_shorten
echo "shorten.zip created"

# Build redirect function  
echo "Building redirect.zip..."
mkdir -p temp_redirect
cd temp_redirect

# Install dependencies
pip install -r ../requirements.txt -t .

# Copy the function code
cp ../redirect.py .

# Create zip file
zip -r ../redirect.zip .

# Clean up
cd ..
rm -rf temp_redirect
echo "redirect.zip created"

# Build options function (no additional dependencies needed)
echo "Building options.zip..."
zip -r options.zip options.py
echo "options.zip created"

cd ..
echo "All Lambda packages built successfully!"
echo ""
echo "Enhanced features added:"
echo "- CloudWatch monitoring and dashboards"
echo "- AWS WAF security protection"
echo "- X-Ray distributed tracing"
echo "- Kinesis Data Firehose analytics"
echo "- S3 analytics data storage"
echo ""
echo "Next steps:"
echo "1. cd terraform"
echo "2. terraform init"
echo "3. terraform apply"

cd ..
echo "All Lambda packages built successfully!"
echo ""
echo "Next steps:"
echo "1. cd terraform"
echo "2. terraform init"
echo "3. terraform apply"
