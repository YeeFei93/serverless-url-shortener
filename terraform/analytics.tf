# Analytics infrastructure for URL Shortener
# S3 storage and Kinesis Data Firehose are included in AWS Free Tier

# S3 bucket for analytics data storage
resource "aws_s3_bucket" "analytics" {
  bucket        = "yee-fei-url-shortener-analytics"
  force_destroy = true

  tags = {
    Name = "URL Shortener Analytics Data"
  }
}

resource "aws_s3_bucket_versioning" "analytics_versioning" {
  bucket = aws_s3_bucket.analytics.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "analytics_encryption" {
  bucket = aws_s3_bucket.analytics.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access for analytics bucket
resource "aws_s3_bucket_public_access_block" "analytics" {
  bucket = aws_s3_bucket.analytics.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# IAM role for Kinesis Data Firehose
resource "aws_iam_role" "firehose_role" {
  name = "url-shortener-firehose-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "firehose.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "Firehose Service Role"
  }
}

# IAM policy for Firehose to access S3
resource "aws_iam_role_policy" "firehose_s3_policy" {
  name = "firehose-s3-policy"
  role = aws_iam_role.firehose_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:AbortMultipartUpload",
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads",
          "s3:PutObject"
        ]
        Resource = [
          aws_s3_bucket.analytics.arn,
          "${aws_s3_bucket.analytics.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${var.aws_region}:*:*"
      }
    ]
  })
}

# Kinesis Data Firehose for URL click analytics
resource "aws_kinesis_firehose_delivery_stream" "url_analytics" {
  name        = "url-shortener-analytics"
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn   = aws_iam_role.firehose_role.arn
    bucket_arn = aws_s3_bucket.analytics.arn
    prefix     = "url-clicks/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/"
    error_output_prefix = "errors/"
    
    buffering_size     = 1   # MB (minimum for free tier efficiency)
    buffering_interval = 60  # seconds (minimum)
    
    compression_format = "GZIP"

    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = aws_cloudwatch_log_group.analytics_log_group.name
      log_stream_name = "S3Delivery"
    }
  }

  tags = {
    Name = "URL Analytics Delivery Stream"
  }
}

# CloudWatch Log Group for analytics
resource "aws_cloudwatch_log_group" "analytics_log_group" {
  name              = "/aws/kinesisfirehose/url-shortener-analytics"
  retention_in_days = 7

  tags = {
    Name = "Analytics Firehose Logs"
  }
}

# IAM role for Lambda to write to Kinesis Data Firehose
resource "aws_iam_role_policy" "lambda_firehose_policy" {
  name = "lambda-firehose-policy"
  role = data.aws_iam_role.lambda_exec.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "firehose:PutRecord",
          "firehose:PutRecordBatch"
        ]
        Resource = [
          aws_kinesis_firehose_delivery_stream.url_analytics.arn
        ]
      }
    ]
  })
}
