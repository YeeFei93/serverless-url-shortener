# API Gateway HTTP API and routes
resource "aws_apigatewayv2_api" "http_api" {
  name          = "url-shortener-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["POST"]
    allow_headers = ["content-type"]
  }

  tags = {
    Name = "URL Shortener API"
  }
}

# Integrations
resource "aws_apigatewayv2_integration" "shorten_integration" {
  api_id             = aws_apigatewayv2_api.http_api.id
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.shorten_url.invoke_arn
  integration_method = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_integration" "redirect_integration" {
  api_id                  = aws_apigatewayv2_api.http_api.id
  integration_type        = "AWS_PROXY"
  integration_uri         = aws_lambda_function.redirect_url.invoke_arn
  integration_method      = "POST"
  payload_format_version  = "2.0"
}

resource "aws_apigatewayv2_integration" "options_integration" {
  api_id                  = aws_apigatewayv2_api.http_api.id
  integration_type        = "AWS_PROXY"
  integration_uri         = aws_lambda_function.options_lambda.invoke_arn
  integration_method      = "POST"
  payload_format_version  = "2.0"
}

# Routes
resource "aws_apigatewayv2_route" "shorten_route" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "POST /shorten"
  target    = "integrations/${aws_apigatewayv2_integration.shorten_integration.id}"
}

resource "aws_apigatewayv2_route" "redirect_route" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "ANY /{short_id}"
  target    = "integrations/${aws_apigatewayv2_integration.redirect_integration.id}"
}

resource "aws_apigatewayv2_route" "options_route" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "OPTIONS /shorten"
  target    = "integrations/${aws_apigatewayv2_integration.options_integration.id}"
}

# Stage
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = "$default"
  auto_deploy = true

  tags = {
    Name = "URL Shortener API Stage"
  }
}

# Lambda permissions
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

resource "aws_lambda_permission" "allow_options" {
  statement_id  = "AllowAPIGatewayInvokeOptions"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.options_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}
