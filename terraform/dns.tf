# SSL certificates and DNS configuration

# Frontend certificate (CloudFront)
resource "aws_acm_certificate" "frontend_cert" {
  domain_name       = "ui.sctp-sandbox.com"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "frontend-cert"
  }
}

resource "aws_route53_record" "frontend_cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.frontend_cert.domain_validation_options : dvo.domain_name => {
      name  = dvo.resource_record_name
      type  = dvo.resource_record_type
      value = dvo.resource_record_value
    }
  }

  zone_id = data.aws_route53_zone.main.zone_id
  name    = each.value.name
  type    = each.value.type
  records = [each.value.value]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "frontend_cert" {
  certificate_arn         = aws_acm_certificate.frontend_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.frontend_cert_validation : record.fqdn]
}

# API certificate (API Gateway)
resource "aws_acm_certificate" "api_cert" {
  domain_name       = "short.sctp-sandbox.com"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "api-cert"
  }
}

resource "aws_route53_record" "api_cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.api_cert.domain_validation_options : dvo.domain_name => {
      name  = dvo.resource_record_name
      type  = dvo.resource_record_type
      value = dvo.resource_record_value
    }
  }

  zone_id = data.aws_route53_zone.main.zone_id
  name    = each.value.name
  type    = each.value.type
  records = [each.value.value]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "api_cert" {
  certificate_arn         = aws_acm_certificate.api_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.api_cert_validation : record.fqdn]
}

# Custom domain for API Gateway
resource "aws_apigatewayv2_domain_name" "short" {
  domain_name = "short.sctp-sandbox.com"

  domain_name_configuration {
    certificate_arn = aws_acm_certificate_validation.api_cert.certificate_arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }

  depends_on = [aws_acm_certificate_validation.api_cert]
}

resource "aws_apigatewayv2_api_mapping" "short_mapping" {
  api_id      = aws_apigatewayv2_api.http_api.id
  domain_name = aws_apigatewayv2_domain_name.short.domain_name
  stage       = aws_apigatewayv2_stage.default.name
}

# DNS records
resource "aws_route53_record" "frontend_alias" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "ui.sctp-sandbox.com"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.cdn.domain_name
    zone_id                = aws_cloudfront_distribution.cdn.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "apigw_alias" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "short.sctp-sandbox.com"
  type    = "A"

  alias {
    name                   = aws_apigatewayv2_domain_name.short.domain_name_configuration[0].target_domain_name
    zone_id                = aws_apigatewayv2_domain_name.short.domain_name_configuration[0].hosted_zone_id
    evaluate_target_health = false
  }
}
