output "api_endpoint" {
  value = aws_apigatewayv2_api.http_api.api_endpoint
}

output "api_gateway_url" {
  description = "Custom domain URL for the API Gateway"
  value       = "https://${aws_apigatewayv2_domain_name.short.domain_name}"
}

output "frontend_url" {
  description = "Custom domain URL for the frontend CloudFront distribution"
  value       = "https://ui.sctp-sandbox.com"
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket hosting the frontend"
  value       = aws_s3_bucket.frontend.bucket
}
