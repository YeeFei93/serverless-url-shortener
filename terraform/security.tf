# AWS WAF (Web Application Firewall) for URL Shortener
# WAF is free tier eligible with 1 Web ACL, 2 rules per Web ACL, and 1 million requests per month

# WAF Web ACL for CloudFront
resource "aws_wafv2_web_acl" "cloudfront_waf" {
  name  = "url-shortener-cloudfront-waf"
  scope = "CLOUDFRONT"

  default_action {
    allow {}
  }

  # Rate limiting rule - prevent abuse
  rule {
    name     = "RateLimitRule"
    priority = 1

    statement {
      rate_based_statement {
        limit              = 1000  # 1000 requests per 5-minute window per IP
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                 = "RateLimitRule"
      sampled_requests_enabled    = true
    }

    action {
      block {}
    }
  }

  # Block common attack patterns
  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                 = "CommonRuleSetMetric"
      sampled_requests_enabled    = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                 = "URLShortenerWAF"
    sampled_requests_enabled    = true
  }

  tags = {
    Name = "URL Shortener WAF - CloudFront"
  }
}

# Note: API Gateway V2 HTTP APIs don't support direct WAF associations.
# Protection is provided through CloudFront WAF above, which covers the frontend.
# The API endpoints are also protected through CloudFront when accessed via the custom domain.

# CloudWatch Log Group for WAF logs (optional but useful for debugging)
resource "aws_cloudwatch_log_group" "waf_log_group" {
  name              = "/aws/waf/url-shortener"
  retention_in_days = 7

  tags = {
    Name = "WAF Logs"
  }
}
