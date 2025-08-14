#!/bin/bash

# Pre-deployment validation script
# Checks that all required tools and configurations are available

set -e

echo "🔍 Validating deployment environment..."

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ERRORS=0

# Check AWS CLI
if command -v aws &> /dev/null; then
    echo -e "${GREEN}✅ AWS CLI is installed${NC}"
    
    # Check AWS credentials
    if aws sts get-caller-identity &> /dev/null; then
        echo -e "${GREEN}✅ AWS credentials are configured${NC}"
        ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
        echo -e "${GREEN}   Account ID: $ACCOUNT_ID${NC}"
    else
        echo -e "${RED}❌ AWS credentials not configured${NC}"
        ERRORS=$((ERRORS + 1))
    fi
else
    echo -e "${RED}❌ AWS CLI is not installed${NC}"
    ERRORS=$((ERRORS + 1))
fi

# Check Terraform
if command -v terraform &> /dev/null; then
    echo -e "${GREEN}✅ Terraform is installed${NC}"
    TERRAFORM_VERSION=$(terraform version -json | jq -r .terraform_version)
    echo -e "${GREEN}   Version: $TERRAFORM_VERSION${NC}"
else
    echo -e "${RED}❌ Terraform is not installed${NC}"
    ERRORS=$((ERRORS + 1))
fi

# Check required files
required_files=(
    "build.sh"
    "lambda/shorten.py"
    "lambda/redirect.py"
    "lambda/options.py"
    "terraform/main.tf"
    "terraform/providers.tf"
    "terraform/variables.tf"
    "frontend/index.html"
)

echo -e "${YELLOW}Checking required files...${NC}"
for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        echo -e "${GREEN}✅ $file${NC}"
    else
        echo -e "${RED}❌ $file (missing)${NC}"
        ERRORS=$((ERRORS + 1))
    fi
done

# Check if build.sh is executable
if [ -f "build.sh" ]; then
    if [ -x "build.sh" ]; then
        echo -e "${GREEN}✅ build.sh is executable${NC}"
    else
        echo -e "${YELLOW}⚠️  build.sh is not executable (will be fixed automatically)${NC}"
        chmod +x build.sh
    fi
fi

# Validate Terraform configuration
if command -v terraform &> /dev/null && [ -d "terraform" ]; then
    echo -e "${YELLOW}Validating Terraform configuration...${NC}"
    cd terraform
    
    if terraform init -backend=false &> /dev/null; then
        echo -e "${GREEN}✅ Terraform init successful${NC}"
        
        if terraform validate &> /dev/null; then
            echo -e "${GREEN}✅ Terraform configuration is valid${NC}"
        else
            echo -e "${RED}❌ Terraform configuration validation failed${NC}"
            ERRORS=$((ERRORS + 1))
        fi
    else
        echo -e "${RED}❌ Terraform init failed${NC}"
        ERRORS=$((ERRORS + 1))
    fi
    
    cd ..
fi

# Check AWS permissions (basic test)
if aws sts get-caller-identity &> /dev/null; then
    echo -e "${YELLOW}Testing basic AWS permissions...${NC}"
    
    # Test permissions for key services
    if aws iam list-roles --max-items 1 &> /dev/null; then
        echo -e "${GREEN}✅ IAM permissions available${NC}"
    else
        echo -e "${YELLOW}⚠️  Limited IAM permissions${NC}"
    fi
    
    if aws s3 ls &> /dev/null; then
        echo -e "${GREEN}✅ S3 permissions available${NC}"
    else
        echo -e "${YELLOW}⚠️  Limited S3 permissions${NC}"
    fi
fi

# Summary
echo -e "\n${YELLOW}Validation Summary:${NC}"
if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}🎉 All checks passed! Ready for deployment.${NC}"
    exit 0
else
    echo -e "${RED}❌ $ERRORS error(s) found. Please fix before deploying.${NC}"
    exit 1
fi
