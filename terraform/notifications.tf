# SNS notifications for URL Shortener
# SNS is included in AWS Free Tier (1,000 notifications per month)

# SNS topic for alerts and notifications
resource "aws_sns_topic" "alerts" {
  name = "url-shortener-alerts"

  tags = {
    Name = "URL Shortener Alerts"
  }
}

# Optional: SNS subscription for email alerts (uncomment and add your email)
# resource "aws_sns_topic_subscription" "email_alerts" {
#   topic_arn = aws_sns_topic.alerts.arn
#   protocol  = "email"
#   endpoint  = "your-email@example.com"  # Replace with your email
# }

# Update CloudWatch alarms to use SNS
resource "aws_cloudwatch_metric_alarm" "high_error_rate" {
  alarm_name          = "url-shortener-high-error-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "High error rate detected in URL shortener"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    FunctionName = "shorten_url"
  }

  tags = {
    Name = "High Error Rate Alarm"
  }
}

resource "aws_cloudwatch_metric_alarm" "ddos_protection" {
  alarm_name          = "url-shortener-potential-ddos"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Count"
  namespace           = "AWS/ApiGatewayV2"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1000"  # Adjust based on expected traffic
  alarm_description   = "High request rate - potential DDoS attack"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    ApiId = aws_apigatewayv2_api.http_api.id
  }

  tags = {
    Name = "Potential DDoS Alarm"
  }
}
