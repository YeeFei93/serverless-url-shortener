#!/bin/bash

# AWS Setup Script for GitHub Actions Deployment
# This script helps set up the necessary AWS resources for automated deployment

set -e

echo "🚀 Setting up AWS resources for GitHub Actions deployment..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get AWS account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>/dev/null || echo "")

if [ -z "$ACCOUNT_ID" ]; then
    echo -e "${RED}❌ AWS CLI not configured or no access. Please run 'aws configure' first.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ AWS Account ID: $ACCOUNT_ID${NC}"

# Function to create OIDC provider
setup_oidc() {
    echo -e "${YELLOW}Setting up OIDC provider...${NC}"
    
    # Check if OIDC provider already exists
    if aws iam get-open-id-connect-provider --open-id-connect-provider-arn "arn:aws:iam::$ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ OIDC provider already exists${NC}"
    else
        aws iam create-open-id-connect-provider \
            --url https://token.actions.githubusercontent.com \
            --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1 \
            --client-id-list sts.amazonaws.com
        echo -e "${GREEN}✅ OIDC provider created${NC}"
    fi
}

# Function to create IAM role
create_role() {
    local role_name="GitHubActionsDeployRole"
    echo -e "${YELLOW}Creating IAM role: $role_name...${NC}"
    
    # Trust policy for GitHub Actions
    cat > trust-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::$ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
          "token.actions.githubusercontent.com:sub": "repo:YeeFei93/serverless-url-shortener:ref:refs/heads/main"
        }
      }
    }
  ]
}
EOF

    # Create role if it doesn't exist
    if aws iam get-role --role-name $role_name >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Role $role_name already exists${NC}"
    else
        aws iam create-role \
            --role-name $role_name \
            --assume-role-policy-document file://trust-policy.json \
            --description "Role for GitHub Actions to deploy serverless URL shortener"
        echo -e "${GREEN}✅ Role $role_name created${NC}"
    fi

    # Attach necessary policies
    policies=(
        "arn:aws:iam::aws:policy/AmazonAPIGatewayAdministrator"
        "arn:aws:iam::aws:policy/AWSLambda_FullAccess"  
        "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
        "arn:aws:iam::aws:policy/AmazonS3FullAccess"
        "arn:aws:iam::aws:policy/CloudFrontFullAccess"
        "arn:aws:iam::aws:policy/AmazonRoute53FullAccess"
        "arn:aws:iam::aws:policy/AWSCertificateManagerFullAccess"
        "arn:aws:iam::aws:policy/IAMFullAccess"
        "arn:aws:iam::aws:policy/CloudWatchFullAccess"
        "arn:aws:iam::aws:policy/AWSWAFv2FullAccess"
        "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
    )

    echo -e "${YELLOW}Attaching policies to role...${NC}"
    for policy in "${policies[@]}"; do
        aws iam attach-role-policy --role-name $role_name --policy-arn $policy
        echo -e "${GREEN}✅ Attached: $(basename $policy)${NC}"
    done

    # Clean up temp file
    rm trust-policy.json

    echo -e "${GREEN}✅ Role setup complete!${NC}"
    echo -e "${YELLOW}Add this to your GitHub repository secrets:${NC}"
    echo -e "${GREEN}AWS_ROLE_ARN: arn:aws:iam::$ACCOUNT_ID:role/$role_name${NC}"
}

# Function to set up Terraform state backend (optional)
setup_terraform_backend() {
    local bucket_name="terraform-state-url-shortener-$ACCOUNT_ID"
    local table_name="terraform-locks-url-shortener"
    
    echo -e "${YELLOW}Setting up Terraform remote state backend...${NC}"
    
    # Create S3 bucket for state
    if aws s3 ls "s3://$bucket_name" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ S3 bucket $bucket_name already exists${NC}"
    else
        aws s3 mb "s3://$bucket_name"
        # Enable versioning
        aws s3api put-bucket-versioning \
            --bucket "$bucket_name" \
            --versioning-configuration Status=Enabled
        # Enable encryption
        aws s3api put-bucket-encryption \
            --bucket "$bucket_name" \
            --server-side-encryption-configuration '{
                "Rules": [
                    {
                        "ApplyServerSideEncryptionByDefault": {
                            "SSEAlgorithm": "AES256"
                        }
                    }
                ]
            }'
        echo -e "${GREEN}✅ S3 bucket $bucket_name created with versioning and encryption${NC}"
    fi
    
    # Create DynamoDB table for locking
    if aws dynamodb describe-table --table-name "$table_name" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ DynamoDB table $table_name already exists${NC}"
    else
        aws dynamodb create-table \
            --table-name "$table_name" \
            --attribute-definitions AttributeName=LockID,AttributeType=S \
            --key-schema AttributeName=LockID,KeyType=HASH \
            --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5
        echo -e "${GREEN}✅ DynamoDB table $table_name created${NC}"
    fi
    
    echo -e "${YELLOW}Update terraform/backend.tf with these values:${NC}"
    echo -e "${GREEN}bucket = \"$bucket_name\"${NC}"
    echo -e "${GREEN}dynamodb_table = \"$table_name\"${NC}"
}

# Main menu
echo -e "${YELLOW}Choose setup option:${NC}"
echo "1. OIDC Setup (Recommended)"
echo "2. Setup Terraform Backend (Optional)"
echo "3. Full Setup (OIDC + Backend)"
echo "4. Exit"

read -p "Enter your choice (1-4): " choice

case $choice in
    1)
        setup_oidc
        create_role
        ;;
    2)
        setup_terraform_backend
        ;;
    3)
        setup_oidc
        create_role
        setup_terraform_backend
        ;;
    4)
        echo -e "${GREEN}Goodbye!${NC}"
        exit 0
        ;;
    *)
        echo -e "${RED}Invalid choice${NC}"
        exit 1
        ;;
esac

echo -e "${GREEN}🎉 Setup completed successfully!${NC}"
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Add the AWS_ROLE_ARN secret to your GitHub repository"
echo "2. Update terraform/backend.tf if you set up remote state"
echo "3. Test the workflow manually from GitHub Actions"
echo "4. Check the GITHUB_ACTIONS_SETUP.md file for detailed instructions"
