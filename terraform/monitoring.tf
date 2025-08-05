# CloudWatch monitoring and observability for URL Shortener
# Demonstrates enterprise-grade monitoring practices for CloudDevOps role

# CloudWatch Log Groups with proper retention
resource "aws_cloudwatch_log_group" "lambda_shorten" {
  name              = "/aws/lambda/url-shortener-shorten"
  retention_in_days = 7

  tags = {
    Name        = "url-shortener-shorten-logs"
    Project     = "serverless-url-shortener"
    Environment = "production"
  }
}

resource "aws_cloudwatch_log_group" "lambda_redirect" {
  name              = "/aws/lambda/url-shortener-redirect"
  retention_in_days = 7

  tags = {
    Name        = "url-shortener-redirect-logs"
    Project     = "serverless-url-shortener"
    Environment = "production"
  }
}

resource "aws_cloudwatch_log_group" "lambda_options" {
  name              = "/aws/lambda/url-shortener-options"
  retention_in_days = 7

  tags = {
    Name        = "url-shortener-options-logs"
    Project     = "serverless-url-shortener"
    Environment = "production"
  }
}

# CloudWatch Dashboard for operational visibility
resource "aws_cloudwatch_dashboard" "url_shortener" {
  dashboard_name = "URL-Shortener-Operations"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/Lambda", "Invocations", "FunctionName", "url-shortener-shorten"],
            [".", "Errors", ".", "."],
            [".", "Duration", ".", "."],
            ["AWS/Lambda", "Invocations", "FunctionName", "url-shortener-redirect"],
            [".", "Errors", ".", "."],
            [".", "Duration", ".", "."]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "Lambda Functions Performance"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
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
          title  = "API Gateway Metrics"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/DynamoDB", "ConsumedReadCapacityUnits", "TableName", aws_dynamodb_table.url_table.name],
            [".", "ConsumedWriteCapacityUnits", ".", "."],
            [".", "UserErrors", ".", "."],
            [".", "SystemErrors", ".", "."]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "DynamoDB Performance"
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
  period              = "120"
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "This metric monitors lambda errors"
  insufficient_data_actions = []

  dimensions = {
    FunctionName = "url-shortener-shorten"
  }

  tags = {
    Name        = "url-shortener-lambda-errors"
    Project     = "serverless-url-shortener"
    Environment = "production"
  }
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

  dimensions = {
    ApiId = aws_apigatewayv2_api.http_api.id
  }

  tags = {
    Name        = "url-shortener-api-errors"
    Project     = "serverless-url-shortener"
    Environment = "production"
  }
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

  dimensions = {
    TableName = aws_dynamodb_table.url_table.name
  }

  tags = {
    Name        = "url-shortener-dynamodb-errors"
    Project     = "serverless-url-shortener"
    Environment = "production"
  }
}
