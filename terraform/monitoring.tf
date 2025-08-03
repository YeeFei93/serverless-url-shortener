# CloudWatch monitoring and alarms for URL Shortener
# All resources in this file are included in AWS Free Tier

# Import existing CloudWatch Log Groups for Lambda functions (auto-created by AWS)
data "aws_cloudwatch_log_group" "shorten_logs" {
  name = "/aws/lambda/shorten_url"
}

data "aws_cloudwatch_log_group" "redirect_logs" {
  name = "/aws/lambda/redirect_url"
}

data "aws_cloudwatch_log_group" "options_logs" {
  name = "/aws/lambda/options_handler"
}

# CloudWatch Dashboard (Free tier includes 3 dashboards with up to 50 metrics each)
resource "aws_cloudwatch_dashboard" "url_shortener_dashboard" {
  dashboard_name = "URLShortenerMetrics"

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
            ["AWS/Lambda", "Invocations", "FunctionName", "shorten_url"],
            ["AWS/Lambda", "Invocations", "FunctionName", "redirect_url"],
            ["AWS/Lambda", "Invocations", "FunctionName", "options_handler"]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Lambda Invocations"
          period  = 300
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
            ["AWS/Lambda", "Errors", "FunctionName", "shorten_url"],
            ["AWS/Lambda", "Errors", "FunctionName", "redirect_url"],
            ["AWS/Lambda", "Errors", "FunctionName", "options_handler"]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Lambda Errors"
          period  = 300
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
            ["AWS/Lambda", "Duration", "FunctionName", "shorten_url"],
            ["AWS/Lambda", "Duration", "FunctionName", "redirect_url"],
            ["AWS/Lambda", "Duration", "FunctionName", "options_handler"]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Lambda Duration"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 18
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/ApiGatewayV2", "Count", "ApiId", aws_apigatewayv2_api.http_api.id],
            ["AWS/ApiGatewayV2", "4xx", "ApiId", aws_apigatewayv2_api.http_api.id],
            ["AWS/ApiGatewayV2", "5xx", "ApiId", aws_apigatewayv2_api.http_api.id]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "API Gateway Requests"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 24
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/DynamoDB", "ConsumedReadCapacityUnits", "TableName", "UrlTable"],
            ["AWS/DynamoDB", "ConsumedWriteCapacityUnits", "TableName", "UrlTable"]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "DynamoDB Capacity"
          period  = 300
        }
      }
    ]
  })
}

# CloudWatch Alarms (Free tier includes 10 alarms)
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
  alarm_actions       = []  # Add SNS topic ARN here if you want email notifications

  dimensions = {
    FunctionName = "shorten_url"
  }

  tags = {
    Name = "Lambda Errors Alarm"
  }
}

resource "aws_cloudwatch_metric_alarm" "api_gateway_4xx" {
  alarm_name          = "url-shortener-api-4xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "4xx"
  namespace           = "AWS/ApiGatewayV2"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "This metric monitors API Gateway 4xx errors"
  alarm_actions       = []

  dimensions = {
    ApiId = aws_apigatewayv2_api.http_api.id
  }

  tags = {
    Name = "API Gateway 4xx Errors Alarm"
  }
}

resource "aws_cloudwatch_metric_alarm" "api_gateway_5xx" {
  alarm_name          = "url-shortener-api-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "5xx"
  namespace           = "AWS/ApiGatewayV2"
  period              = "300"
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "This metric monitors API Gateway 5xx errors"
  alarm_actions       = []

  dimensions = {
    ApiId = aws_apigatewayv2_api.http_api.id
  }

  tags = {
    Name = "API Gateway 5xx Errors Alarm"
  }
}
