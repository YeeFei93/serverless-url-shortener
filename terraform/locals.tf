# Local values for consistent tagging and naming
locals {
  common_tags = {
    Project     = "serverless-url-shortener"
    Environment = "production"
    ManagedBy   = "terraform"
    Repository  = "https://github.com/YeeFei93/serverless-url-shortener"
    Owner       = "YeeFei93"
  }
  
  name_prefix = "url-shortener"
}
