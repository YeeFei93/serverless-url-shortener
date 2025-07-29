output "api_endpoint" {
  description = "Base URL of the HTTP API Gateway"
  value       = aws_apigatewayv2_api.http_api.api_endpoint
}
