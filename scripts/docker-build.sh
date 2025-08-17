#!/bin/bash

# Docker build script for Lambda functions
# This script builds Docker images for all Lambda functions and pushes to ECR
#
# USAGE:
#   ./scripts/docker-build.sh
#
# Docker-based Lambda deployment is now the standard. ZIP-based deployment is deprecated.
# Ensure you have AWS CLI and Docker installed and configured.
#
# This script will:
#   - Build Docker images for each Lambda function
#   - Create ECR repositories if needed
#   - Push images to ECR
#   - Print next steps for Terraform deployment

set -e

echo "🐳 Building Docker images for Lambda functions..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check for AWS CLI
if ! command -v aws &> /dev/null; then
    echo -e "${RED}Error: AWS CLI is not installed. Please install it before running this script.${NC}"
    exit 1
fi

# Check for Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: Docker is not installed. Please install it before running this script.${NC}"
    exit 1
fi

# AWS Account ID and Region
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION=$(aws configure get region || echo "us-east-1")
ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

echo -e "${GREEN}AWS Account ID: $AWS_ACCOUNT_ID${NC}"
echo -e "${GREEN}AWS Region: $AWS_REGION${NC}"
echo -e "${GREEN}ECR Registry: $ECR_REGISTRY${NC}"

# Function to create ECR repository if it doesn't exist
create_ecr_repo() {
    local repo_name=$1
    echo -e "${YELLOW}Checking ECR repository: $repo_name${NC}"
    
    if ! aws ecr describe-repositories --repository-names "$repo_name" &>/dev/null; then
        echo -e "${YELLOW}Creating ECR repository: $repo_name${NC}"
        aws ecr create-repository --repository-name "$repo_name" --region "$AWS_REGION"
        echo -e "${GREEN}✅ Created ECR repository: $repo_name${NC}"
    else
        echo -e "${GREEN}✅ ECR repository already exists: $repo_name${NC}"
    fi
}

# Function to build and push Docker image
build_and_push() {
    local function_name=$1
    local dockerfile=$2
    local repo_name="serverless-url-shortener-${function_name}"
    local image_tag="latest"
    
    echo -e "${YELLOW}Building Docker image for: $function_name${NC}"
    
    # Create ECR repository
    create_ecr_repo "$repo_name"
    
    # Build Docker image
    docker build -f "$dockerfile" -t "$repo_name:$image_tag" .
    
    # Tag for ECR
    docker tag "$repo_name:$image_tag" "$ECR_REGISTRY/$repo_name:$image_tag"
    
    # Login to ECR
    aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "$ECR_REGISTRY"
    
    # Push to ECR
    docker push "$ECR_REGISTRY/$repo_name:$image_tag"
    
    echo -e "${GREEN}✅ Successfully built and pushed: $function_name${NC}"
    echo -e "${GREEN}   Image URI: $ECR_REGISTRY/$repo_name:$image_tag${NC}"
}

# Build images for all Lambda functions
cd lambda

echo -e "${YELLOW}Building Lambda function Docker images...${NC}"

build_and_push "shorten" "Dockerfile.shorten"
build_and_push "redirect" "Dockerfile.redirect"  
build_and_push "options" "Dockerfile.options"

cd ..

echo -e "${GREEN}🎉 All Docker images built and pushed successfully!${NC}"
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Update terraform/lambda.tf to use container images"
echo "2. Run terraform plan to see the changes"
echo "3. Run terraform apply to deploy containerized functions"
#!/bin/bash

# Docker build script for Lambda functions
# This script builds Docker images for all Lambda functions and pushes to ECR

set -e

echo "🐳 Building Docker images for Lambda functions..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# AWS Account ID and Region
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION=$(aws configure get region || echo "us-east-1")
ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

echo -e "${GREEN}AWS Account ID: $AWS_ACCOUNT_ID${NC}"
echo -e "${GREEN}AWS Region: $AWS_REGION${NC}"
echo -e "${GREEN}ECR Registry: $ECR_REGISTRY${NC}"

# Function to create ECR repository if it doesn't exist
create_ecr_repo() {
    local repo_name=$1
    echo -e "${YELLOW}Checking ECR repository: $repo_name${NC}"
    
    if ! aws ecr describe-repositories --repository-names "$repo_name" &>/dev/null; then
        echo -e "${YELLOW}Creating ECR repository: $repo_name${NC}"
        aws ecr create-repository --repository-name "$repo_name" --region "$AWS_REGION"
        echo -e "${GREEN}✅ Created ECR repository: $repo_name${NC}"
    else
        echo -e "${GREEN}✅ ECR repository already exists: $repo_name${NC}"
    fi
}

# Function to build and push Docker image
build_and_push() {
    local function_name=$1
    local dockerfile=$2
    local repo_name="serverless-url-shortener-${function_name}"
    local image_tag="latest"
    
    echo -e "${YELLOW}Building Docker image for: $function_name${NC}"
    
    # Create ECR repository
    create_ecr_repo "$repo_name"
    
    # Build Docker image
    docker build -f "$dockerfile" -t "$repo_name:$image_tag" .
    
    # Tag for ECR
    docker tag "$repo_name:$image_tag" "$ECR_REGISTRY/$repo_name:$image_tag"
    
    # Login to ECR
    aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "$ECR_REGISTRY"
    
    # Push to ECR
    docker push "$ECR_REGISTRY/$repo_name:$image_tag"
    
    echo -e "${GREEN}✅ Successfully built and pushed: $function_name${NC}"
    echo -e "${GREEN}   Image URI: $ECR_REGISTRY/$repo_name:$image_tag${NC}"
}

# Build images for all Lambda functions
cd lambda

echo -e "${YELLOW}Building Lambda function Docker images...${NC}"

build_and_push "shorten" "Dockerfile.shorten"
build_and_push "redirect" "Dockerfile.redirect"  
build_and_push "options" "Dockerfile.options"

cd ..

echo -e "${GREEN}🎉 All Docker images built and pushed successfully!${NC}"
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Update terraform/lambda.tf to use container images"
echo "2. Run terraform plan to see the changes"
echo "3. Run terraform apply to deploy containerized functions"
