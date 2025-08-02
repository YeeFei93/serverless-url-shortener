provider "aws" {
  region = var.aws_region
}

resource "aws_dynamodb_table" "url_table" {
  name         = "UrlTable"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "short_id"

  attribute {
    name = "short_id"
    type = "S"
  }
}

data "aws_iam_role" "lambda_exec" {
  name = "lambda-url-shortener-role"
}

resource "aws_iam_role_policy_attachment" "lambda_dynamodb_policy" {
  role       = data.aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

resource "aws_iam_role_policy_attachment" "lambda_basic_exec" {
  role       = data.aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "shorten_url" {
  filename         = "${path.module}/../lambda/shorten.zip"
  function_name    = "shorten_url"
  role             = data.aws_iam_role.lambda_exec.arn
  handler          = "shorten.lambda_handler"
  runtime          = "python3.9"
  source_code_hash = filebase64sha256("${path.module}/../lambda/shorten.zip")
}

resource "aws_lambda_function" "redirect_url" {
  filename         = "${path.module}/../lambda/redirect.zip"
  function_name    = "redirect_url"
  role             = data.aws_iam_role.lambda_exec.arn
  handler          = "redirect.lambda_handler"
  runtime          = "python3.9"
  source_code_hash = filebase64sha256("${path.module}/../lambda/redirect.zip")
}

resource "aws_apigatewayv2_api" "http_api" {
  name          = "url-shortener-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["POST"]
    allow_headers = ["content-type"]
  }
}

resource "aws_apigatewayv2_integration" "shorten_integration" {
  api_id             = aws_apigatewayv2_api.http_api.id
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.shorten_url.invoke_arn
  integration_method = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "shorten_route" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "POST /shorten"
  target    = "integrations/${aws_apigatewayv2_integration.shorten_integration.id}"
}

resource "aws_apigatewayv2_integration" "redirect_integration" {
  api_id                  = aws_apigatewayv2_api.http_api.id
  integration_type        = "AWS_PROXY"
  integration_uri         = aws_lambda_function.redirect_url.invoke_arn
  integration_method      = "POST"  # << Fix here
  payload_format_version  = "2.0"
}

resource "aws_apigatewayv2_route" "redirect_route" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "ANY /{short_id}"
  target    = "integrations/${aws_apigatewayv2_integration.redirect_integration.id}"
}

resource "aws_lambda_permission" "allow_shortening" {
  statement_id  = "AllowAPIGatewayInvokeShorten"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.shorten_url.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "allow_redirect" {
  statement_id  = "AllowAPIGatewayInvokeRedirect"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.redirect_url.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_lambda_function" "options_lambda" {
  filename         = "${path.module}/../lambda/options.zip"
  function_name    = "options_handler"
  role             = data.aws_iam_role.lambda_exec.arn
  handler          = "options.lambda_handler"
  runtime          = "python3.9"
  source_code_hash = filebase64sha256("${path.module}/../lambda/options.zip")
}

resource "aws_apigatewayv2_integration" "options_integration" {
  api_id                  = aws_apigatewayv2_api.http_api.id
  integration_type        = "AWS_PROXY"
  integration_uri         = aws_lambda_function.options_lambda.invoke_arn
  integration_method      = "POST"
  payload_format_version  = "2.0"
}

resource "aws_apigatewayv2_route" "options_route" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "OPTIONS /shorten"
  target    = "integrations/${aws_apigatewayv2_integration.options_integration.id}"
}

resource "aws_lambda_permission" "allow_options" {
  statement_id  = "AllowAPIGatewayInvokeOptions"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.options_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}

resource "aws_cloudfront_distribution" "frontend" {
  origin {
    domain_name = "yee-fei-url-shortener-frontend.s3-website-us-east-1.amazonaws.com"
    origin_id   = "S3-Frontend"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    }
  }

  enabled             = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-Frontend"

    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  price_class = "PriceClass_100" # Cheapest (US, Canada, Europe)

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Name = "URL Shortener Frontend"
  }
}

