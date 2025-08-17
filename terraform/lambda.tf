# Lambda functions for URL shortener

# Lambda functions for URL shortener (Docker image deployment)
resource "aws_lambda_function" "shorten_url" {
  function_name    = "shorten_url"
  role             = data.aws_iam_role.lambda_exec.arn
  package_type     = "Image"
  image_uri        = "${var.shorten_image_uri}"

  tracing_config {
    mode = "Active"
  }

  tags = {
    Name = "URL Shortener - Shorten Function"
  }
}

resource "aws_lambda_function" "redirect_url" {
  function_name    = "redirect_url"
  role             = data.aws_iam_role.lambda_exec.arn
  package_type     = "Image"
  image_uri        = "${var.redirect_image_uri}"

  tracing_config {
    mode = "Active"
  }

  tags = {
    Name = "URL Shortener - Redirect Function"
  }
}

resource "aws_lambda_function" "options_lambda" {
  function_name    = "options_handler"
  role             = data.aws_iam_role.lambda_exec.arn
  package_type     = "Image"
  image_uri        = "${var.options_image_uri}"

  tracing_config {
    mode = "Active"
  }

  tags = {
    Name = "URL Shortener - CORS Options Function"
  }
}
