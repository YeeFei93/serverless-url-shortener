# CloudWatch monitoring and observability for URL Shortener
# Comprehensive monitoring for enterprise-grade DevOps practices

# CloudWatch Log Groups with proper retention
resource "aws_cloudwatch_log_group" "shorten" {
  name              = "/aws/lambda/url-shortener-shorten"
  retention_in_days = 7
  tags              = local.common_tags
}

resource "aws_cloudwatch_log_group" "redirect" {
  name              = "/aws/lambda/url-shortener-redirect"
  retention_in_days = 7
  tags              = local.common_tags
}

resource "aws_cloudwatch_log_group" "options" {
  name              = "/aws/lambda/url-shortener-options"
  retention_in_days = 7
  tags              = local.common_tags
}

# Comprehensive CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "url_shortener" {
  dashboard_name = "URL-Shortener-Operations"

  dashboard_body = jsonencode({
    widgets = [
      # API Gateway Metrics
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApiGatewayV2", "Count", "ApiId", aws_apigatewayv2_api.http_api.id],
            [".", "4XXError", ".", "."],
            [".", "5XXError", ".", "."],
            [".", "IntegrationLatency", ".", "."]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "API Gateway - Request Metrics"
          view   = "timeSeries"
        }
      },

      # Lambda Function Performance
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/Lambda", "Duration", "FunctionName", "url-shortener-shorten"],
            [".", ".", ".", "url-shortener-redirect"],
            [".", ".", ".", "url-shortener-options"],
            [".", "Invocations", ".", "url-shortener-shorten"],
            [".", ".", ".", "url-shortener-redirect"],
            [".", ".", ".", "url-shortener-options"]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "Lambda Functions - Performance"
          view   = "timeSeries"
        }
      },

      # Lambda Error Rates
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/Lambda", "Errors", "FunctionName", "url-shortener-shorten"],
            [".", ".", ".", "url-shortener-redirect"],
            [".", ".", ".", "url-shortener-options"],
            [".", "Throttles", ".", "url-shortener-shorten"],
            [".", ".", ".", "url-shortener-redirect"],
            [".", ".", ".", "url-shortener-options"]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "Lambda Functions - Error & Throttle Rates"
          view   = "timeSeries"
        }
      },

      # DynamoDB Performance
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/DynamoDB", "ConsumedReadCapacityUnits", "TableName", aws_dynamodb_table.url_table.name],
            [".", "ConsumedWriteCapacityUnits", ".", "."],
            [".", "ItemCount", ".", "."],
            [".", "UserErrors", ".", "."],
            [".", "SystemErrors", ".", "."]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "DynamoDB - Performance & Usage"
          view   = "timeSeries"
        }
      },

      # CloudFront Distribution Metrics
      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/CloudFront", "Requests", "DistributionId", aws_cloudfront_distribution.cdn.id],
            [".", "BytesDownloaded", ".", "."],
            [".", "4xxErrorRate", ".", "."],
            [".", "5xxErrorRate", ".", "."]
          ]
          period = 300
          region = "us-east-1" # CloudFront metrics are always in us-east-1
          title  = "CloudFront - Distribution Metrics"
          view   = "timeSeries"
        }
      },

      # Cost Tracking
      {
        type   = "metric"
        x      = 12
        y      = 12
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/Billing", "EstimatedCharges", "Currency", "USD", "ServiceName", "AmazonApiGateway"],
            [".", ".", ".", ".", ".", "AWSLambda"],
            [".", ".", ".", ".", ".", "AmazonDynamoDB"],
            [".", ".", ".", ".", ".", "AmazonS3"],
            [".", ".", ".", ".", ".", "AmazonCloudFront"]
          ]
          period  = 86400 # Daily
          stat    = "Maximum"
          region  = "us-east-1" # Billing metrics are in us-east-1
          title   = "Cost Breakdown by Service"
          view    = "timeSeries"
          stacked = true
        }
      }
    ]
  })
}

# CloudWatch Alarms for proactive monitoring
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "url-shortener-lambda-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "This metric monitors lambda errors"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    FunctionName = "url-shortener-shorten"
  }

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "api_gateway_errors" {
  alarm_name          = "url-shortener-api-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "5XXError"
  namespace           = "AWS/ApiGatewayV2"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "This metric monitors API Gateway 5XX errors"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    ApiId = aws_apigatewayv2_api.http_api.id
  }

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "high_api_latency" {
  alarm_name          = "url-shortener-high-api-latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "IntegrationLatency"
  namespace           = "AWS/ApiGatewayV2"
  period              = "300"
  statistic           = "Average"
  threshold           = "1000" # 1 second
  alarm_description   = "This metric monitors API Gateway latency"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    ApiId = aws_apigatewayv2_api.http_api.id
  }

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "dynamodb_errors" {
  alarm_name          = "url-shortener-dynamodb-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "UserErrors"
  namespace           = "AWS/DynamoDB"
  period              = "300"
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "This metric monitors DynamoDB user errors"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    TableName = aws_dynamodb_table.url_table.name
  }

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "dynamodb_throttles" {
  alarm_name          = "url-shortener-dynamodb-throttles"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ReadThrottles"
  namespace           = "AWS/DynamoDB"
  period              = "300"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "This metric monitors DynamoDB read throttles"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    TableName = aws_dynamodb_table.url_table.name
  }

  tags = local.common_tags
}

# SNS Topic for Alerts
resource "aws_sns_topic" "alerts" {
  name = "url-shortener-alerts"
  tags = local.common_tags
}

resource "aws_sns_topic_subscription" "email_alerts" {
  count     = var.alert_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# Custom CloudWatch Log Insights Queries
resource "aws_cloudwatch_query_definition" "error_analysis" {
  name = "url-shortener-error-analysis"

  log_group_names = [
    aws_cloudwatch_log_group.shorten.name,
    aws_cloudwatch_log_group.redirect.name,
    aws_cloudwatch_log_group.options.name
  ]

  query_string = <<EOF
fields @timestamp, @message, @logStream
| filter @message like /ERROR/
| sort @timestamp desc
| limit 100
EOF
}

resource "aws_cloudwatch_query_definition" "performance_analysis" {
  name = "url-shortener-performance-analysis"

  log_group_names = [
    aws_cloudwatch_log_group.shorten.name,
    aws_cloudwatch_log_group.redirect.name,
    aws_cloudwatch_log_group.options.name
  ]

  query_string = <<EOF
fields @timestamp, @duration, @billedDuration, @memorySize, @maxMemoryUsed, @logStream
| filter @type = "REPORT"
| stats avg(@duration), max(@duration), min(@duration) by bin(5m)
| sort @timestamp desc
EOF
}

# Application Performance Monitoring with X-Ray
resource "aws_xray_sampling_rule" "url_shortener" {
  rule_name      = "url-shortener-sampling"
  priority       = 9000
  version        = 1
  reservoir_size = 1
  fixed_rate     = 0.1
  url_path       = "*"
  host           = "*"
  http_method    = "*"
  service_type   = "*"
  service_name   = "*"
  resource_arn   = "*"

  tags = local.common_tags
}
