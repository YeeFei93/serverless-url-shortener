# Provider and common data sources
provider "aws" {
  region = var.aws_region
}

data "aws_route53_zone" "main" {
  name         = "sctp-sandbox.com"
  private_zone = false
}

data "aws_iam_role" "lambda_exec" {
  name = "lambda-url-shortener-role"
}
