variable "aws_region" {
  description = "AWS region to deploy to"
  type        = string
  default     = "us-east-1"
}
variable "shorten_image_uri" {
  description = "URI of the Docker image for the shorten Lambda function"
  type        = string
}

variable "redirect_image_uri" {
  description = "URI of the Docker image for the redirect Lambda function"
  type        = string
}

variable "options_image_uri" {
  description = "URI of the Docker image for the options Lambda function"
  type        = string
}
variable "alert_email" {
  description = "Email address for CloudWatch alerts"
  type        = string
  default     = ""
}
