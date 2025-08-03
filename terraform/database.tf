# DynamoDB table for URL storage
resource "aws_dynamodb_table" "url_table" {
  name         = "UrlTable"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "short_id"

  attribute {
    name = "short_id"
    type = "S"
  }

  tags = {
    Name = "URL Shortener Table"
  }
}
