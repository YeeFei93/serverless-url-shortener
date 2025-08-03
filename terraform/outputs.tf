output "api_endpoint" {
  value = aws_apigatewayv2_api.http_api.api_endpoint
}

# New outputs for monitoring and analytics
output "cloudwatch_dashboard_url" {
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.url_shortener_dashboard.dashboard_name}"
  description = "URL to access the CloudWatch dashboard"
}

output "analytics_s3_bucket" {
  value       = aws_s3_bucket.analytics.bucket
  description = "S3 bucket name for analytics data"
}

output "cloudfront_waf_web_acl_id" {
  value       = aws_wafv2_web_acl.cloudfront_waf.id
  description = "WAF Web ACL ID for CloudFront"
}

output "firehose_delivery_stream" {
  value       = aws_kinesis_firehose_delivery_stream.url_analytics.name
  description = "Kinesis Data Firehose delivery stream name"
}

output "sns_alerts_topic" {
  value       = aws_sns_topic.alerts.arn
  description = "SNS topic ARN for alerts"
}
