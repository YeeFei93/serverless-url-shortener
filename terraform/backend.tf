# Terraform backend configuration for remote state
# Uncomment and configure this block to use remote state storage
# This is recommended for production deployments

# terraform {
#   backend "s3" {
#     bucket         = "your-terraform-state-bucket"
#     key            = "serverless-url-shortener/terraform.tfstate"  
#     region         = "us-east-1"
#     encrypt        = true
#     dynamodb_table = "your-terraform-locks-table"
#   }
# }

# Alternative: Use Terraform Cloud
# terraform {
#   cloud {
#     organization = "your-org"
#     workspaces {
#       name = "serverless-url-shortener"
#     }
#   }
# }
