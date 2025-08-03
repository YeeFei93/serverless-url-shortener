#!/bin/bash

# Build script for Lambda deployment packages
# This script creates the ZIP files needed for Terraform deployment

echo "Building Lambda deployment packages..."

# Create lambda directory if it doesn't exist
mkdir -p lambda

# Build shorten function
echo "Building shorten.zip..."
cd lambda
zip -r shorten.zip shorten.py
echo "shorten.zip created"

# Build redirect function  
echo "Building redirect.zip..."
zip -r redirect.zip redirect.py
echo "redirect.zip created"

# Build options function
echo "Building options.zip..."
zip -r options.zip options.py
echo "options.zip created"

cd ..
echo "All Lambda packages built successfully!"
echo ""
echo "Next steps:"
echo "1. cd terraform"
echo "2. terraform init"
echo "3. terraform apply"
