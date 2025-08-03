# Main Terraform configuration for Serverless URL Shortener
# This file serves as the entry point and includes all other configuration files

# Include all configuration files
# Provider and data sources are in providers.tf
# Database resources are in database.tf  
# IAM resources are in iam.tf
# Lambda functions are in lambda.tf
# API Gateway resources are in api-gateway.tf
# Frontend (S3/CloudFront) resources are in frontend.tf
# DNS and certificates are in dns.tf

# This modular approach makes the infrastructure easier to:
# - Navigate and understand
# - Maintain and update
# - Review in pull requests  
# - Reuse across environments