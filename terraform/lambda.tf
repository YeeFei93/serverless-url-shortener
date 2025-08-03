# Lambda functions for URL shortener
resource "aws_lambda_function" "shorten_url" {
  filename         = "${path.module}/../lambda/shorten.zip"
  function_name    = "shorten_url"
  role             = data.aws_iam_role.lambda_exec.arn
  handler          = "shorten.lambda_handler"
  runtime          = "python3.9"
  source_code_hash = filebase64sha256("${path.module}/../lambda/shorten.zip")

  tags = {
    Name = "URL Shortener - Shorten Function"
  }
}

resource "aws_lambda_function" "redirect_url" {
  filename         = "${path.module}/../lambda/redirect.zip"
  function_name    = "redirect_url"
  role             = data.aws_iam_role.lambda_exec.arn
  handler          = "redirect.lambda_handler"
  runtime          = "python3.9"
  source_code_hash = filebase64sha256("${path.module}/../lambda/redirect.zip")

  tags = {
    Name = "URL Shortener - Redirect Function"
  }
}

resource "aws_lambda_function" "options_lambda" {
  filename         = "${path.module}/../lambda/options.zip"
  function_name    = "options_handler"
  role             = data.aws_iam_role.lambda_exec.arn
  handler          = "options.lambda_handler"
  runtime          = "python3.9"
  source_code_hash = filebase64sha256("${path.module}/../lambda/options.zip")

  tags = {
    Name = "URL Shortener - CORS Options Function"
  }
}
